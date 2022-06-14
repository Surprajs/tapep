from picamera.array import PiRGBArray
from picamera import PiCamera
import cv2
from datetime import datetime
import argparse
import numpy as np

parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--c', type=bool, default=False, help='Open camera with calibrated matrix')
args = parser.parse_args()

res = (640,480)
camera = PiCamera()
camera.resolution = res
camera.framerate = 32
rawCapture = PiRGBArray(camera, size=res)

decoder = cv2.QRCodeDetector()
if args.c:
    with np.load("camera_parameters.npz") as file:
        ret, mtx, dist = file["ret"], file["mtx"], file["dist"]
    newcameramtx, roi = cv2.getOptimalNewCameraMatrix(mtx, dist, res, 0, res)

for frame in camera.capture_continuous(rawCapture, format="bgr", use_video_port=True):
    image = frame.array
    if args.c:
        image = cv2.undistort(image,mtx,dist,None,newcameramtx)
    try:
        data, _, _ = decoder.detectAndDecode(image)
        if data:
            print(f"{datetime.now().strftime('%H:%M:%S')} -- {data}")
    except:
        print("chuj")
    cv2.imshow("Frame", image)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break
    rawCapture.truncate(0)