import matplotlib.pyplot as plt
import PySimpleGUI as sg
from czifile import imread
import numpy as np
import os
import napari
from segmentify import segmentation
from PIL import Image

def napari_launch(image): 

    # parse input file
    example_image = os.path.join(os.path.abspath(os.path.dirname(__file__)), image)

    with napari.gui_qt():
            viewer = napari.Viewer()

            #viewer.window.remove_dock_widget("all")

            # instantiate the widget
            gui = segmentation.Gui()

            # add our new widget to the napari viewer
            viewer.window.add_dock_widget(gui)

            # keep the dropdown menus in the gui in sync with the layer model
            viewer.layers.events.changed.connect(
                lambda x: gui.refresh_choices())

            gui.refresh_choices()

            # load data
            viewer.open(example_image)

def convert_to_png(image):
    img = imread(image)
    img = img.transpose((2, 3, 1, 0, 4))
    img = img.squeeze()

    greenblue_ch = np.stack(
           (np.zeros(img.shape[0:2], dtype='uint8'), img[:, :, 0]/img[:, :, 0].max(), img[:, :, 1]/img[:, :, 1].max()), axis=2)

    plt.imsave(values["-IN-"][:-4] + 'gb.png', greenblue_ch)

sg.theme("DarkTeal2")
layout = [[sg.T("")], [sg.Text("Choose a file: "), sg.Input(), sg.FileBrowse(key="-IN-")], [sg.Button("Convert")]]

# Building Window
window = sg.Window('CZI file converter', layout, size=(600, 150))

while True:
    event, values = window.read()
    if event == sg.WIN_CLOSED or event == "Exit":
        break
    elif event == "Convert":
        convert_to_png(values["-IN-"])
        napari_launch(values["-IN-"][:-4] + 'gb.png')