// import QtQuick 2.1
// import QtQuick.Controls 1.0
// import QtQuick.Layouts 1.0
// import org.julialang 1.0
// import Qt.labs.platform 1.1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.julialang
import Qt.labs.platform


ApplicationWindow {
  id: root
  title: "Ising Simulation"
  width: canvas.width + 256
  height: canvas.height + 256
  visible: true

  Item{
    anchors.left: parent.left
    width: childrenRect.width
    height: childrenRect.height

    ColumnLayout{
      Layout.alignment: Qt.AlignHCenter
      Text{
        Layout.alignment: Qt.AlignHCenter
        text: "Updates per frame: "

      }
      Text{
        Layout.alignment: Qt.AlignHCenter
        text: obs.upf
      }
    }
  }

  // Whole application in a column
  // Screen stuff above, panels and text under
  ColumnLayout{
    // anchors.fill: parent
    anchors.centerIn: parent
    spacing: 32

    // Buttons at top of window
    Item{
      Layout.alignment: Qt.AlignHCenter
      width: childrenRect.width
      height: childrenRect.height

      ColumnLayout{
        spacing: 2
        // Init Graph Button
        Button {
          Layout.alignment: Qt.AlignCenter
          text: "Initialize Graph"
          onClicked: {
            Julia.initIsing()
          }
        }
        // Pause Simulation Button
        Button{
          Layout.alignment: Qt.AlignCenter
          text: {
            if(obs.isPaused)
            {
              "Paused"
            }
            else{
              "Running"
            }
          }
          onClicked: {
            obs.isPaused = !obs.isPaused
          }
        }
      }
    }


    // Middle row
    // Brush - Screen - Temperature
    RowLayout{
      spacing: 6
      Layout.alignment: Qt.AlignHCenter
      // Brush Buttons and radius slider
      RowLayout{

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
            onClicked: {
              obs.brush = -1
            }
          }

        }
        // Radius Slider
        ColumnLayout{
          Text{
            text: "Radius \n" + rSlider.value
          }
          Slider{
            id: rSlider
            value: obs.brushR
            orientation: Qt.Vertical
            // minimumValue: 1
            // maximumValue: 100
            from: 1
            to: 100
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


      JuliaCanvas{
        Layout.alignment: Qt.AlignCenter
        id: canvas
        width: obs.gSize 
        height: {
          if(obs.gSize > 512)
          {
            obs.gSize
          }
          else{
            512
          }
        }

        paintFunction: showlatest

        MouseArea{
          anchors.fill: parent
          onClicked: {
            Julia.circleToStateQML(mouseY, mouseX)
          }
        }

      }


      //  Temperature Slider
      Item{
        Layout.alignment: Qt.AlignCenter
        width: childrenRect.width
        height: childrenRect.height
        RowLayout{
          spacing: 2
          // Temp Slider
          Slider{
            height: 256
            value: obs.TIs
            orientation: Qt.Vertical
            // minimumValue: 0.0
            // maximumValue: 20
            from: 0.0
            to: 20.
            stepSize: 0.01
            onValueChanged: {
              obs.TIs = value
            }
          }
          // Temperature text
          Item{
            width: 32
            Text{
              Layout.alignment: Qt.AlignCenter
              text: qsTr("T=\n") + obs.TIs.toFixed(2)
            }
          }
        }
      }
    }

    // Panels under plot
    // Inserting Defects
    // Magnetization
    ColumnLayout{
      Layout.alignment: Qt.AlignCenter
      spacing: 2

      // Defects textfield & Button
      Item{
        Layout.alignment: Qt.AlignCenter

        width: childrenRect.width
        height: childrenRect.height

        ColumnLayout{
          spacing: 2
          Layout.alignment: Qt.AlignHCenter

          TextField{
            Layout.alignment: Qt.AlignHCenter
            id: defectText
            placeholderText: "0"
            validator: IntValidator {
              bottom: 0; top: 100
            }
          }

          Button{
            Layout.alignment: Qt.AlignHCenter
            text: "Insert Defects"
            onClicked: {
              if(!(isNaN(parseInt(defectText.text))))
                {
                  if(parseInt(defectText.text) > 99)
                {
                  defectText.text = "99"
                }

                 Julia.addRandomDefectsQML(parseInt(defectText.text))
                }
                defectText.text = ""
            }
          }
        }
      }

      // Text under plot, magnetization
      Item{
        width: childrenRect.width
        height: childrenRect.height
        Layout.alignment: Qt.AlignHCenter
        ColumnLayout{
          Layout.alignment: Qt.AlignHCenter
          Text{
            Layout.alignment: Qt.AlignHCenter
            text: "Magnetization: " + obs.M.toFixed(1)
          }
        }
      }

      // Initiate Temperature sweep

      Button{
        Layout.alignment: Qt.AlignHCenter
        text: "Temperature Sweep"
        onClicked: {
          var component = Qt.createComponent("./Tsweep.qml")
          var window = component.createObject(root)
          window.show()
          if(!root.tsweep.active){
            println("Active")
          }

        }
      }
    }
  }


  // Timer for display
  Timer {
    // Set interval in ms:
    property int frames: 1
    interval: 1/60*1000; running: true; repeat: true
    onTriggered: {
      Julia.timedFunctions();
      canvas.update();
      frames += 1
    }
  }
}
