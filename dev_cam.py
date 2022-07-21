import cv2
from datetime import datetime
import numpy as np
import pandas as pd
# import seaborn as sns
# import matplotlib.pyplot as plt
# Updated to run various Dev proj. video functions by J. Whear on 13Jan2022, updated 20Jan2022

# stop_threads is used to stop recording at specified sections of OEP recordings
stop_threads = False

class SimpleVid:
    def __init__(self,camera, path):
        self.cap = cv2.VideoCapture(camera)
        print('cam started')
        self.capError = False
        if not self.cap.isOpened():
            print('error opening aux vid, probably doesn\'t exist')
            self.capError = True
            return
        self.openOutfile(path, self.cap.get(4) , self.cap.get(3))

    def run(self, camera, path):
        while(self.cap.isOpened()):
            ret, frame = self.cap.read()
            #frame = cv2.flip(frame,flipCode = 0)# flipcodes: 1 = hflip, 0 = vflip
            if not ret:
                print('Error loading frame, probably last frame')
                return
            cv2.imshow('Video', frame)
            self.out.write(frame)
            if cv2.waitKey(33) & 0xFF == ord('q'):
                self.cap.release()
                cv2.destroyAllWindows()
                try: self.out.release()
                except: pass
                return
    def openOutfile(self, path, height, width):
        self.outPath = path
        fourcc = cv2.VideoWriter_fourcc(*'XVID')
        self.out = cv2.VideoWriter(path,fourcc, 30, (int(width),int(height)))

def run_rec(video_path, rat, day, cond, camera):
    cap = cv2.VideoCapture(camera)
    fourcc = cv2.VideoWriter_fourcc(*'MJPG')
    width= int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height= int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = 30
    writer = cv2.VideoWriter(video_path, fourcc, fps, (640,  480))
    font = cv2.FONT_HERSHEY_SIMPLEX

    while(cap.isOpened()):
        ret, frame = cap.read()
        cv2.putText(frame,str(rat+day+cond),(5,20),font,0.7,(0,0,255),1) # Color is in BGR
        cv2.putText(frame,str(datetime.now()),(5,40),font,0.5,(0,0,255),1) # Location format is X,Y
        writer.write(frame)
        cv2.imshow('TNEL Dev. Proj ' + rat + day, frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            cap.release()
            writer.release()
            cv2.destroyAllWindows()
            break
        if stop_threads:
            cap.release()
            writer.release()
            cv2.destroyAllWindows()
            print(video_path + ' Video Saved Successfully!')
            break

def compile_video_from_png(video_path,rat,day,seconds):
    fps = 1
    fourcc = cv2.VideoWriter_fourcc(*'MJPG')
    video = cv2.VideoWriter('{}\{}{}.avi'.format(video_path, rat, day), fourcc, fps,(640,480))

    for i in range(seconds):
        img = cv2.imread('{}\devTestday_Test-{}.png'.format(video_path, i))
        video.write(img)
    
    cv2.destroyAllWindows()
    video.release()

def overlay_accel (video_path, rat, day, img_loc, output_path):
    i = 0
    j = 0
    file_name = '{}{}-{}.png'.format(rat,day,i)
    image = cv2.imread(img_loc + '\\' + file_name)
    scale_percent = 30 # percent of the original image
    height = int(image.shape[0] * scale_percent / 100)
    width = int(image.shape[1] * scale_percent / 100)
    dim = (width,height)
    image_resized = cv2.resize(image,dim, interpolation = cv2.INTER_AREA)
    cap = cv2.VideoCapture(video_path)
    fourcc = cv2.VideoWriter_fourcc(*'MJPG')
    width= int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height= int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = 30
    writer = cv2.VideoWriter(output_path, fourcc, fps, (640,  480))
    font = cv2.FONT_HERSHEY_SIMPLEX
    alpha = 0.6
    print('Overlaying {} {} acceleration onto recording'.format(rat,day))

    while(cap.isOpened()):
        j += 1
        if j > 29:
            i += 1
            j = 0
            file_name = '{}{}-{}.png'.format(rat,day,i)
            image = cv2.imread(img_loc + '\\' + file_name)
            image_resized = cv2.resize(image,dim, interpolation = cv2.INTER_AREA)
            print('Writing {}'.format(file_name))
        ret, frame = cap.read()
        image_resized_x, image_resized_y, image_resized_z = image_resized.shape[0], image_resized.shape[1], image_resized.shape[2]
        image_x = image_resized_x
        image_y = image_resized_y
        try: # If the frames number isn't exactly the same, it will fail here. Break out and keep going
            added_image = cv2.addWeighted(frame[480-image_x:480,640-image_y:640,:],alpha,image_resized[0:image_x,0:image_y,:],1-alpha,0)
        
        except:
            cap.release()
            writer.release()
            cv2.destroyAllWindows()
            break

        frame[480-image_x:480,640-image_y:640] = added_image # X then Y
        writer.write(frame)
        cv2.imshow('TNEL Dev. Proj ' + rat + day, frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            cap.release()
            writer.release()
            cv2.destroyAllWindows()
            break

def create_accel_png(rat,day,cleandata_matlab_struct,output_path,seconds,condition): # Seconds is int
    df = pd.DataFrame(cleandata_matlab_struct)
    
    # Reformat DataFrame
    df_final = df.iloc[32:35,:]
    df_final = df_final.T
    df_final.columns = ['aux1 (x)', 'aux2 (y)', 'aux3 (z)']
    df_final['abs'] = np.sqrt(abs(pow(df_final['aux1 (x)'],2) + pow(df_final['aux2 (y)'],2) + pow(df_final['aux3 (z)'],2)))

    for i in range(len(df_final)):
        df_final_seconds = df_final[:i] #i
        # Plot results using Seaborn
        '''
        ax = sns.lineplot(data=df_final_seconds['abs'],color='#FF5733')
        ax.set(ylim = (0,2000))
        ax.set(xlim =(0,seconds))
        ax.set_title('Acceleration Vs. Time (s) - {} {}'.format(rat,day))
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('Acceleration')
        plt.savefig('{}\{}{}-{}.png'.format(output_path,rat,day,i))
        percent = round(int(i)/int(len(df_final))*100,2)
        print('{} acceleration graphing is {}% complete'.format(condition,percent))
        '''


def runSimpleVid(camera, path):
    sv = SimpleVid(camera,path)