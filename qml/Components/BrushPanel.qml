// Brush stuff
// Brush Buttons and radius slider

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.julialang
import Qt.labs.platform

RowLayout{

    property bool clamp: false

    ColumnLayout{
        Text{
            Layout.alignment: Qt.AlignHCenter
            text: "Type"
        }
        Layout.alignment: Qt.AlignCenter

        Button{
            Layout.preferredWidth: brushButton.width
            text: "1"
            onClicked: {
                obs.brush = 1
            }
        }
        Button{
            Layout.preferredWidth: brushButton.width
            text: "0"
            onClicked: {
                obs.brush = 0
            }
        }
        Button{
            id: brushButton
            text: "-1"
            // palette: {
            //     button: "gray"
            // }
            onClicked: {
                obs.brush = -1
            }
        }
        Text{
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Clamp")
        }
        Switch{
            Layout.alignment: Qt.AlignHCenter
            checked: clamp
            onCheckedChanged: {
                clamp = !clamp
            }
        }

    }
    // Radius Slider
    ColumnLayout{
        Text{
            Layout.alignment: Qt.AlignHCenter
            text: "Radius"
        }
        Text{
            Layout.alignment: Qt.AlignHCenter
            text: rSlider.value
        }
        Slider{
            Layout.alignment: Qt.AlignHCenter
            id: rSlider
            value: obs.brushR
            orientation: Qt.Vertical
            // minimumValue: 1
            // maximumValue: 100
            from: 1
            to: {
                Math.floor(obs.gSize/2)-1
            }
            stepSize: 1
            onValueChanged: {
                obs.brushR = value
            }
            onPressedChanged: {
                // show slider Hover when pressed, hide otherwise
                if( pressed )
                {

                }
                else {
                    Julia.newCirc()
                }
            }
        }
    }
}