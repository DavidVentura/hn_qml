import QtQuick 2.0
import Ubuntu.Components 1.3 as UITK

UITK.Page {
    Column {
        anchors.fill: parent
        Text {
            text: "$Username"
        }
        Text {
            text: "Karma: $Karma - Submitted: $submission_count - Comments: $comment_count"
        }
        Text {
            text: "About: $About"
        }
        // MAYBE list of comments by user
    }

}
