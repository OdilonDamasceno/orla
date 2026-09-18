import QtQuick
import "../singletons"

Canvas {
    id: root
    property real cornerRadius: parent ? parent.radius : 0

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()

    anchors.fill: parent
    z: 1

    onPaint: {
        const context = root.getContext("2d");
        const inset = 0.5;
        const left = inset;
        const top = inset;
        const right = root.width - inset;
        const bottom = root.height - inset;
        const radius = Math.max(0, Math.min(root.cornerRadius, width / 2, height / 2) - inset);
        const white = Theme.glassHighlight;
        const black = "#00000000";

        function strokeSide(x1, y1, x2, y2, startColor, endColor) {
            const gradient = context.createLinearGradient(x1, y1, x2, y2);
            gradient.addColorStop(0, startColor);
            gradient.addColorStop(1, endColor);

            context.beginPath();
            context.moveTo(x1, y1);
            context.lineTo(x2, y2);
            context.strokeStyle = gradient;
            context.stroke();
        }

        function strokeCorner(centerX, centerY, startAngle, endAngle, color) {
            context.beginPath();
            context.arc(centerX, centerY, radius, startAngle, endAngle, false);
            context.strokeStyle = color;
            context.stroke();
        }

        context.reset();
        context.lineWidth = 1;

        strokeSide(left + radius, top, right - radius, top, white, black);
        strokeSide(right, top + radius, right, bottom - radius, black, white);
        strokeSide(right - radius, bottom, left + radius, bottom, white, black);
        strokeSide(left, bottom - radius, left, top + radius, black, white);

        strokeCorner(left + radius, top + radius, Math.PI, Math.PI * 1.5, white);
        strokeCorner(right - radius, top + radius, Math.PI * 1.5, Math.PI * 2, black);
        strokeCorner(right - radius, bottom - radius, 0, Math.PI / 2, white);
        strokeCorner(left + radius, bottom - radius, Math.PI / 2, Math.PI, black);
    }
}
