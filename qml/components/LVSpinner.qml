import QtQuick 2.12
import QtQuick.Shapes 1.12
import QtGraphicalEffects 1.0

Rectangle {
    property int triggerY: -units.gu(10)
    property int maxY: triggerY * 1.5
    property variant listView

    id: spin
    x: parent.width / 2 - width / 2
    y: Math.max(listView.verticalOvershoot, maxY) * -1.5

    width: units.gu(5)
    height: units.gu(5)
    z: 2
    color: 'white'
    rotation: listView.verticalOvershoot * -1.5
    radius: units.gu(5)

    Shape {
        z: 3
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 16

        ShapePath {

            fillColor: "transparent"
            strokeColor: "darkBlue"
            strokeWidth: units.gu(0.1)
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: arc
                centerX: spin.width / 2
                centerY: spin.height / 2
                radiusX: units.gu(1)
                radiusY: units.gu(1)
                startAngle: 0
                sweepAngle: 180
            }
        }
    }
    layer.enabled: true
    layer.effect: DropShadow {
        width: spin.width
        height: spin.height
        x: spin.x
        y: spin.y
        visible: spin.visible

        source: spin

        horizontalOffset: 0
        verticalOffset: 0
        radius: 10
        samples: 20
        color: "#999"
    }
}
