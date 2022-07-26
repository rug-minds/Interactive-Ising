import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.julialang
import Qt.labs.platform

import "Components"
import "TSweepWindow"

ApplicationWindow {
  id: root
  title: "Ising Simulation"
  // width: canvas.width + 256
  // height: canvas.height + 256
  width: 512 + 256
  height: 512 + 256
  visible: true

  // UPS Counter
  UpdateCounter{
    anchors.left: parent.left
  }

  // Save Button
  Image{
    anchors.right: parent.right
    width: 32
    height: 26
    source: "Icons/cam.png"
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: false
      onClicked: {
        Julia.saveGImgQML()
      }
    }
  }

  TopPanel{
    id: toppanel
    // Layout.alignment: Qt.AlignHCenter
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
  }

  JuliaCanvas{
    // Layout.alignment: Qt.AlignCenter
    anchors.centerIn: parent
    id: canvas
    height: obs.imgSize
    width: obs.imgSize
    // width: {
    //   if(obs.gSize > 500)
    //   {
    //     return obs.gSize
    //   }
    //   else
    //   {
    //     return ob
    //   }
    // }
    // height: {
    //   if(obs.gSize > 500)
    //   {
    //     return obs.gSize
    //   }
    //   else
    //   {
    //     return 500
    //   }
    // }

    paintFunction: showlatest

    MouseArea{
      anchors.fill: parent
      onClicked: {
        Julia.circleToStateQML(mouseY, mouseX, bpanel.clamp)
      }
    }

  }

  BrushPanel{
    id: bpanel
    anchors.left: parent.left
    anchors.verticalCenter: canvas.verticalCenter
    anchors.margins: 32
    // Layout.alignment: Qt.AlignVCenter
  }

  TempSlider{
    anchors.margins: 32

    anchors.right: parent.right
    anchors.verticalCenter: canvas.verticalCenter
    // Layout.alignment: Qt.AlignCenter
  }
  BottomPanel{
    anchors.margins: 32
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    // Layout.alignment: Qt.AlignCenter
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
