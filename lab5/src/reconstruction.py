import cv2
import numpy as np

import utils as h
import maths as mth


def compute_proj_camera(F, i):
    # Result 9.15 of MVG (v = 0, lambda = 1). It assumes P1 = [I|0]

    # compute epipole e'
    e = mth.nullspace(F.T)

    # build [e']_x
    ske = mth.hat_operator(e)

    # compute P
    P = np.concatenate((ske@F, e), axis=1)

    return P


def estimate_3d_points(P1, P2, xr1, xr2):
    # Triangulate 3D points from camera matrices
    Xprj = cv2.triangulatePoints(P1, P2, xr1, xr2) 

    # Divide by the last column 
    Xprj = Xprj / Xprj[3, :]

    if h.debug >2:
        print("  X estimated:\n", Xprj)

    return Xprj


def compute_reproj_error(X, P1, P2, xr1, xr2):
    # project 3D points using P
    xp1 = P1@X
    xp2 = P2@X
    xp1 = euclid(xp1.T).T
    xp2 = euclid(xp2.T).T

    # compute reprojection error
    error = np.sum(np.sum((xr1-xp1)**2)+np.sum((xr2-xp2)**2))

    return error


def transform(aff_hom, Xprj, cams_pr):
    # Algorithm 19.2 of MVG

    Xaff = aff_hom@Xprj
    Xaff = Xaff / Xaff[3, :]

    cams_aff = [cam@np.linalg.inv(aff_hom) for cam in cams_pr]

    return Xaff, cams_aff


def resection(tracks, i):
    # extract 3D-2D correspondences from tracks
    pts3d = []
    pts2d = []
    for tk in tracks:
        if tk.pt[3] != 0 and i in tk.views:
            pts3d.append(tk.pt)
            pts2d.append(tk.views[i])
    pts3d = np.asarray(pts3d)
    pts2d = np.asarray(pts2d)

    # convert to homogeneous coordinates
    pts2d = homog(pts2d)

    # RANSAC
    n = pts3d.shape[0]
    max_it = 1000
    p = 0.999
    th = 1 - np.cos(0.004)
    eps = np.finfo(float).eps

    best_inliers = []
    it = 0
    while it < max_it:
        points = np.random.choice(range(n), 6, replace=False)
        P = camera_matrix(pts3d[points], pts2d[points])

        d = np.sum((euclid(pts2d)-euclid((P@pts3d.T).T))**2, axis=1)
        inliers = np.where(d < th)[0]

        if len(inliers) > len(best_inliers):
            best_inliers = inliers

        fracinliers = len(best_inliers) / n
        pNoOutliers = 1 - fracinliers**6
        pNoOutliers = max(eps, pNoOutliers)  # avoid division by -Inf
        pNoOutliers = min(1 - eps, pNoOutliers)  # avoid division by 0
        max_it = min(max_it, np.log(1 - p) / np.log(pNoOutliers))

        it += 1

    if len(best_inliers) < 6:
        raise ValueError('There must be at least 6 inliers to compute the camera matrix.')

    P = camera_matrix(pts3d[best_inliers], pts2d[best_inliers])

    # TODO: minimize geometric error

    if h.debug >= 0:
        print('    Camera Matrix estimated')
    if h.debug > 1:
        print('      Camera Matrix: {}\n'.format(P))

    return P


def camera_matrix(pts3d, pts2d):
    # normalize points
    pts3d, T1 = normalize3dpts(pts3d)
    pts2d, T2 = normalize2dpts(pts2d)

    # DLT algorithm
    A = np.empty((2*6, 12))
    for i in range(6):
        X = pts3d[i]
        x, y, w = pts2d[i]
        A[2 * i, :] = np.concatenate((np.zeros(4), -w * X, y * X))
        A[2 * i + 1, :] = np.concatenate((w * X, np.zeros(4), -x * X))

    u, s, vh = np.linalg.svd(A)
    p = vh.T[:, -1]
    P = p.reshape((3, 4))

    # denormalize P
    P = T2.T @ P @ T1
    P /= P[-1, -1]

    return P


def homog(x):
    return np.concatenate((x, np.ones((x.shape[0], 1))), axis=1)


def euclid(x):
    return x[:, :-1] / x[:, [-1]]


def normalize2dpts(pts):
    mean = np.mean(pts[:, :2], axis=0, dtype=np.float32)
    S = np.sqrt(2.) / np.std(pts[:, :2], dtype=np.float32)
    T = np.float32(np.array([[S, 0, -S * mean[0]],
                             [0, S, -S * mean[1]],
                             [0, 0, 1]]))
    pts = T @ pts.T
    return pts.T, T


def normalize3dpts(pts):
    mean = np.mean(pts[:, :3], axis=0, dtype=np.float32)
    S = np.sqrt(2.) / np.std(pts[:, :3], dtype=np.float32)
    T = np.float32(np.array([[S, 0, 0, -S * mean[0]],
                             [0, S, 0, -S * mean[1]],
                             [0, 0, S, -S * mean[2]],
                             [0, 0, 0, 1]]))
    pts = T @ pts.T
    return pts.T, T


def KRt_from_P(P):
    """
    Factorize the camera matrix into K,R,t as P = K[R|t]
    """

    K, R = RQ_factorization(P[:, :3])

    # ensure K has positive diagonal
    T = np.diag(np.sign(np.diag(K))) 
    K = np.dot(K, T)
    R = np.dot(T, R)
    t = np.linalg.solve(K, P[:,3])
    # ensure det(R) = 1
    if np.linalg.det(R) < 0:         
        R = -R
        t = -t
    # normalise K
    K /= K[2, 2]                     

    return K, R, t


def RQ_factorization(A):
    """
    Decompose a matrix into a triangular times rotation.(from PCV)
    """

    Q, R = np.linalg.qr(np.flipud(A).T)
    R = np.flipud(R.T)
    Q = Q.T
    return R[:, ::-1], Q[::-1, :]
