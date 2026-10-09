/*
 * daedric-morrowind — SDDM theme (Qt6 greeter, pure QtQuick)
 * Basalt + brass shrine lit by ember; every rune is live text set in
 * OMW Ayembedt (SIL OFL), which maps Latin A–Z onto the Daedric alphabet.
 * Inscriptions are editable in theme.conf.
 */

import QtQuick
import QtQuick.Window

Item {
    id: root
    width:  Screen.width
    height: Screen.height

    // palette shared with the DaedricMorrowind window decoration
    readonly property color cVoid:    "#060505"
    readonly property color cBasalt:  "#100c0b"
    readonly property color cBrass:   "#6e4a38"
    readonly property color cBrassHi: "#86604a"
    readonly property color cBrassLo: "#3a261d"
    readonly property color cBone:    "#b3a58c"
    readonly property color cPeach:   "#c2633c"
    readonly property color cEmber:   "#a8402a"
    readonly property color cFlame:   "#7d1d15"
    readonly property color cBlood:   "#3f0e0b"
    readonly property color cAsh:     "#3a3735"
    readonly property color cCrest:   "#e39a6a"   // brightest a rune gets, at the crest of a heat wave

    readonly property real   u:        height / 1080
    readonly property string latin:    config.latinFont || "Noto Serif"
    readonly property string runes:    daedricFont.status === FontLoader.Ready ? daedricFont.name : latin

    function inscription(v, fallback) {
        var t = (v || fallback).toString().toUpperCase().replace(/[^A-Z ]/g, "")
        return t.charAt(t.length - 1) === " " ? t : t + " "
    }
    readonly property string ringInner:   inscription(config.ringInner,   "FEAR NOT FOR I AM WATCHFUL YOU HAVE BEEN CHOSEN")
    readonly property string ringOuter:   inscription(config.ringOuter,   "MANY FALL BUT ONE REMAINS MANY FALL BUT ONE REMAINS")
    readonly property string bannerLeft:  inscription(config.bannerLeft,  "COME NEREVAR FRIEND OR TRAITOR COME").trim()
    readonly property string bannerRight: inscription(config.bannerRight, "COME AND LOOK UPON THE HEART").trim()

    property bool   loginPending: false
    property string errorMsg:     ""
    property var    sessionNames: []
    property int    sessionIdx:   sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string sessionLabel: sessionNames.length > sessionIdx ? sessionNames[sessionIdx] : "default session"
    property real   pulse:        0
    property real   wave:         0
    property date   now:          new Date()
    property alias  nameField:    nameBox.input
    property alias  passField:    passBox.input

    FontLoader { id: daedricFont; source: "fonts/OMWAyembedt.otf" }

    SequentialAnimation on pulse {
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 2600; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 2600; easing.type: Easing.InOutSine }
    }
    NumberAnimation on wave { from: 0; to: Math.PI * 2; duration: 9000; loops: Animation.Infinite }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // sessionModel exposes names only through delegates
    Repeater {
        model: sessionModel
        Item {
            visible: false
            Component.onCompleted: {
                var a = root.sessionNames.slice()
                while (a.length <= index) a.push("")
                a[index] = model.name; root.sessionNames = a
            }
        }
    }

    function cycleSession(d) {
        if (sessionNames.length === 0) return
        sessionIdx = (sessionIdx + d + sessionNames.length) % sessionNames.length
    }

    function doLogin() {
        if (loginPending) return
        if (nameField.text.length === 0) { nameField.forceActiveFocus(); return }
        if (passField.text.length === 0) { passField.forceActiveFocus(); return }
        loginPending = true; errorMsg = ""
        sddm.login(nameField.text, passField.text, sessionIdx)
    }

    // Tamrielic calendar for the real date
    function tamrielDate(d) {
        var days   = ["Sundas", "Morndas", "Tirdas", "Middas", "Turdas", "Fredas", "Loredas"]
        var months = ["Morning Star", "Sun's Dawn", "First Seed", "Rain's Hand", "Second Seed", "Midyear",
                      "Sun's Height", "Last Seed", "Hearthfire", "Frostfall", "Sun's Dusk", "Evening Star"]
        var n = d.getDate(), sfx = "th"
        if (n % 100 < 11 || n % 100 > 13) sfx = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
        return days[d.getDay()] + ", " + n + sfx + " of " + months[d.getMonth()]
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginPending = false
            root.errorMsg = "The lock holds. Wrong password."
            passField.text = ""; passField.forceActiveFocus()
            shake.restart()
        }
        function onLoginSucceeded() { root.opacity = 0 }
    }
    Behavior on opacity { NumberAnimation { duration: 450 } }

    Component.onCompleted: {
        nameField.text = userModel.lastUser
        var first = nameField.text.length > 0 ? passField : nameField
        first.forceActiveFocus()
    }

    // ---- backdrop -----------------------------------------------------------
    Rectangle { anchors.fill: parent; color: root.cVoid }
    Image {
        anchors.fill: parent
        source: config.background || "assets/background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }
    // the Heart breathing under the floor
    Image {
        source: "assets/glow.png"
        width: root.width * 0.9; height: root.height * 0.75
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.72
        opacity: 0.02 + 0.05 * root.pulse
    }

    // ash on the wind
    Repeater {
        model: 46
        Rectangle {
            readonly property real lane:  Math.random()
            readonly property real drift: 16000 + Math.random() * 22000
            readonly property real size:  (1 + Math.random() * 2.2) * root.u
            width: size; height: size; radius: size / 2
            color: root.cBone
            opacity: 0.08 + Math.random() * 0.22
            y: lane * root.height + Math.sin(root.wave * 2 + index) * 14 * root.u
            NumberAnimation on x {
                from: -20 - Math.random() * root.width; to: root.width + 20
                duration: drift; loops: Animation.Infinite
            }
        }
    }
    // embers rising
    Repeater {
        model: 16
        Rectangle {
            id: ember
            readonly property real lane: 0.2 + Math.random() * 0.6
            readonly property real life: 7000 + Math.random() * 9000
            width: 2.4 * root.u; height: width; radius: width / 2
            color: index % 3 === 0 ? root.cPeach : root.cEmber
            x: lane * root.width + Math.sin(root.wave * 3 + index * 1.7) * 26 * root.u
            ParallelAnimation {
                running: true; loops: Animation.Infinite
                NumberAnimation { target: ember; property: "y"; from: root.height + 10; to: root.height * 0.45; duration: ember.life }
                SequentialAnimation {
                    NumberAnimation { target: ember; property: "opacity"; from: 0; to: 0.85; duration: ember.life * 0.25 }
                    NumberAnimation { target: ember; property: "opacity"; from: 0.85; to: 0; duration: ember.life * 0.75 }
                }
            }
        }
    }

    // ---- reusable pieces ----------------------------------------------------
    component Diamond: Rectangle {
        property real size: 7 * root.u
        width: size; height: size; rotation: 45
        color: root.cBrassHi; antialiasing: true
    }

    // Morrowind menu box: near-black panel, double brass rule, diamond corners
    component Plate: Item {
        property bool hot: false
        Rectangle { anchors.fill: parent; color: root.cVoid; opacity: 0.86 }
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: parent.hot ? root.cBrassHi : root.cBrass }
        Rectangle { anchors.fill: parent; anchors.margins: 4 * root.u; color: "transparent"; border.width: 1; border.color: root.cBrassLo }
        Diamond { anchors.horizontalCenter: parent.left;  anchors.verticalCenter: parent.top }
        Diamond { anchors.horizontalCenter: parent.right; anchors.verticalCenter: parent.top }
        Diamond { anchors.horizontalCenter: parent.left;  anchors.verticalCenter: parent.bottom }
        Diamond { anchors.horizontalCenter: parent.right; anchors.verticalCenter: parent.bottom }
    }

    // glowing rune text: peach core, blood stroke
    component Rune: Text {
        font.family: root.runes
        color: root.cPeach
        style: Text.Outline; styleColor: root.cBlood
        renderType: Text.QtRendering
    }

    component Label: Text {
        font.family: root.latin
        font.pixelSize: 15 * root.u
        color: root.cBrassHi
    }

    component RingText: Item {
        id: ringText
        property string text: ""
        property real radius: 100
        property real px: 24
        property int crests: 2          // heat waves on the ring at once
        property real drift: 1          // +1 / -1: which way the heat travels
        Repeater {
            model: ringText.text.length
            Item {
                readonly property real heat: Math.pow(0.5 + 0.5 * Math.sin(ringText.drift * root.wave - index / ringText.text.length * Math.PI * 2 * ringText.crests), 3)
                x: ringText.width / 2; y: ringText.height / 2
                rotation: index * 360 / ringText.text.length
                Rune {
                    text: ringText.text.charAt(index)
                    color: Qt.tint(root.cPeach, Qt.rgba(root.cCrest.r, root.cCrest.g, root.cCrest.b, parent.heat))
                    font.pixelSize: ringText.px
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -ringText.radius
                }
            }
        }
    }

    component Banner: Item {
        id: banner
        property string text: ""
        property real phase: 0
        width: 64 * root.u
        height: col.height + 56 * root.u
        Rectangle { x: 0; width: 1; height: parent.height; color: root.cBrassLo }
        Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: root.cBrassLo }
        Rectangle { width: parent.width; height: 1; color: root.cBrass }
        Rectangle { width: parent.width; height: 1; y: parent.height - 1; color: root.cBrass }
        Diamond { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.top }
        Diamond { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.bottom }
        Rectangle { anchors.fill: parent; color: root.cVoid; opacity: 0.45; z: -1 }
        Column {
            id: col
            anchors.centerIn: parent
            spacing: 1 * root.u
            Repeater {
                model: banner.text.length
                Item {
                    readonly property bool gap: banner.text.charAt(index) === " "
                    readonly property real heat: 0.5 + 0.5 * Math.sin(root.wave + banner.phase - index * 0.42)
                    width: banner.width; height: (gap ? 12 : 27) * root.u
                    Rune {
                        visible: !parent.gap
                        anchors.centerIn: parent
                        text: banner.text.charAt(index)
                        font.pixelSize: 24 * root.u
                        color: Qt.rgba(0.30 + 0.48 * parent.heat, 0.06 + 0.32 * parent.heat * parent.heat, 0.04 + 0.18 * parent.heat * parent.heat, 1)
                        styleColor: "#1f0706"
                    }
                }
            }
        }
    }

    component Field: Item {
        id: field
        property alias input: input
        property string label: ""
        property bool secret: false
        width: parent.width; height: 62 * root.u
        Label { text: field.label; font.capitalization: Font.AllUppercase; font.letterSpacing: 3 * root.u; font.pixelSize: 12 * root.u; color: root.cBrass }
        Rectangle {
            id: well
            y: 20 * root.u; width: parent.width; height: 40 * root.u
            color: "#0b0908"
            border.width: 1; border.color: input.activeFocus ? root.cEmber : root.cBrassLo
            TextInput {
                id: input
                anchors.fill: parent; anchors.leftMargin: 12 * root.u; anchors.rightMargin: 12 * root.u
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                font.family: root.latin; font.pixelSize: 18 * root.u
                color: field.secret ? "transparent" : root.cBone
                selectionColor: root.cBlood; selectedTextColor: root.cBone
                echoMode: field.secret ? TextInput.Password : TextInput.Normal
                cursorDelegate: Item {}
                activeFocusOnTab: true
                enabled: !root.loginPending
                Keys.onReturnPressed: field.accepted()
                Keys.onEnterPressed: field.accepted()
            }
            // password shown as a line of runes, drawn from a fixed sequence so
            // nothing about the real characters is revealed
            Row {
                id: runeRow
                visible: field.secret
                anchors.verticalCenter: parent.verticalCenter
                x: 12 * root.u
                spacing: 3 * root.u
                Repeater {
                    model: field.secret ? Math.min(input.length, 22) : 0
                    Rune {
                        text: "AYEMSEHTVEHKDOHTROTHLYR".charAt(index)
                        font.pixelSize: 21 * root.u
                    }
                }
            }
            Rectangle {
                id: caret
                visible: input.activeFocus
                width: 2 * root.u; height: 22 * root.u
                anchors.verticalCenter: parent.verticalCenter
                x: 12 * root.u + (field.secret ? runeRow.width + (input.length > 0 ? 4 * root.u : 0)
                                               : Math.min(input.cursorRectangle.x, well.width - 26 * root.u))
                color: root.cEmber
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 520 }
                    NumberAnimation { to: 1; duration: 520 }
                }
            }
        }
        signal accepted()
        MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }
    }

    component Button: Item {
        id: button
        property string text: ""
        signal clicked()
        activeFocusOnTab: true
        width: buttonLabel.implicitWidth + 44 * root.u; height: 36 * root.u
        Plate { anchors.fill: parent; hot: buttonArea.containsMouse || button.activeFocus }
        Label {
            id: buttonLabel
            anchors.centerIn: parent
            text: button.text
            font.letterSpacing: 2 * root.u
            color: buttonArea.containsMouse || button.activeFocus ? root.cBone : root.cBrassHi
        }
        MouseArea { id: buttonArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.clicked() }
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
    }

    // ---- banners ------------------------------------------------------------
    Banner {
        text: root.bannerLeft
        x: root.width * 0.055
        anchors.verticalCenter: parent.verticalCenter
    }
    Banner {
        text: root.bannerRight
        phase: Math.PI
        x: root.width * (1 - 0.055) - width
        anchors.verticalCenter: parent.verticalCenter
    }

    // ---- sigil --------------------------------------------------------------
    // layers, outside in: tick ring, outer script, orbiting embers, inner script,
    // two counter-turning eight-point stars, ripples, the rune
    Item {
        id: sigil
        width: 440 * root.u; height: width
        anchors.horizontalCenter: parent.horizontalCenter
        y: 36 * root.u
        readonly property real c: width / 2

        component Spin: RotationAnimation { loops: Animation.Infinite }
        // a square outline centred on the sigil with its corners at radius r
        component Frame: Rectangle {
            property real r: 100
            anchors.centerIn: parent
            width: r * Math.SQRT2; height: width
            color: "transparent"; border.width: 1; antialiasing: true
        }
        component Star: Item {
            id: star
            property real r: 100
            property color line: root.cBrassLo
            property color gem: root.cBrassHi
            anchors.fill: parent
            Frame { r: star.r; border.color: star.line }
            Frame { r: star.r; border.color: star.line; rotation: 45 }
            Repeater {
                model: 8
                Item {
                    x: sigil.c; y: sigil.c; rotation: index * 45 + 45
                    Diamond { size: 5 * root.u; color: star.gem; x: -size / 2; y: -star.r - size / 2 }
                }
            }
        }
        component Ripple: Rectangle {
            id: ripple
            property real t: 0
            property int delay: 0
            anchors.centerIn: parent
            width: (150 + 290 * t) * root.u; height: width; radius: width / 2
            color: "transparent"; border.width: 1; border.color: root.cEmber
            opacity: 0.45 * (1 - t) * Math.min(1, t * 6)
            SequentialAnimation on t {
                PauseAnimation { duration: ripple.delay }
                NumberAnimation { from: 0; to: 1; duration: 6400; loops: Animation.Infinite; easing.type: Easing.OutQuad }
            }
        }

        Image { source: "assets/glow.png"; anchors.centerIn: parent; width: parent.width * 0.9; height: width; opacity: 0.12 + 0.20 * root.pulse }

        // tick ring: 72 marks, every sixth long
        Item {
            anchors.fill: parent
            Spin on rotation { from: 360; to: 0; duration: 260000 }
            Repeater {
                model: 72
                Item {
                    x: sigil.c; y: sigil.c; rotation: index * 5
                    Rectangle {
                        readonly property bool major: index % 6 === 0
                        width: 1; height: (major ? 9 : 4) * root.u
                        x: -0.5; y: -228 * root.u
                        color: major ? root.cBrassHi : root.cBrassLo
                    }
                }
            }
        }
        Rectangle { anchors.centerIn: parent; width: 432 * root.u; height: width; radius: width / 2; color: "transparent"; border.width: 1; border.color: root.cBrass }
        Repeater {
            model: 4
            Item {
                x: sigil.c; y: sigil.c; rotation: index * 90
                Diamond { size: 8 * root.u; x: -size / 2; y: -216 * root.u - size / 2 }
            }
        }
        RingText {
            anchors.fill: parent
            text: root.ringOuter; radius: 208 * root.u; px: 26 * root.u
            Spin on rotation { from: 0; to: 360; duration: 120000 }
        }

        Rectangle { anchors.centerIn: parent; width: 350 * root.u; height: width; radius: width / 2; color: "transparent"; border.width: 1; border.color: root.cBrassLo }
        // embers riding the inner circle
        Item {
            anchors.fill: parent
            Spin on rotation { from: 0; to: 360; duration: 38000 }
            Repeater {
                model: 3
                Item {
                    x: sigil.c; y: sigil.c; rotation: index * 120
                    Rectangle {
                        width: 5 * root.u; height: width; radius: width / 2
                        x: -width / 2; y: -175 * root.u - width / 2
                        color: root.cCrest; opacity: 0.55 + 0.45 * root.pulse
                    }
                    Rectangle {
                        width: 13 * root.u; height: width; radius: width / 2
                        x: -width / 2; y: -175 * root.u - width / 2
                        color: root.cEmber; opacity: 0.22
                    }
                }
            }
        }
        RingText {
            anchors.fill: parent
            text: root.ringInner; radius: 160 * root.u; px: 21 * root.u
            crests: 3; drift: -1
            Spin on rotation { from: 360; to: 0; duration: 90000 }
        }

        Rectangle { anchors.centerIn: parent; width: 268 * root.u; height: width; radius: width / 2; color: "transparent"; border.width: 1; border.color: root.cBrassLo; opacity: 0.8 }
        Star {
            r: 128 * root.u
            Spin on rotation { from: 0; to: 360; duration: 150000 }
        }
        Star {
            r: 104 * root.u
            line: root.cBlood; gem: root.cEmber
            Spin on rotation { from: 360; to: 0; duration: 96000 }
        }
        Ripple {}
        Ripple { delay: 3200 }

        // the rune, with a faint larger ghost breathing behind it
        Rune {
            anchors.centerIn: parent
            text: sigilRune.text
            font.pixelSize: 128 * root.u
            scale: 1.16 + 0.10 * root.pulse
            opacity: 0.10 + 0.08 * root.pulse
            style: Text.Normal
        }
        Rune {
            id: sigilRune
            anchors.centerIn: parent
            text: (nameField.text.replace(/[^A-Za-z]/g, "").charAt(0) || "A").toUpperCase()
            font.pixelSize: 128 * root.u
            color: Qt.tint(root.cPeach, Qt.rgba(root.cCrest.r, root.cCrest.g, root.cCrest.b, 0.25 + 0.55 * root.pulse))
            scale: 0.98 + 0.03 * root.pulse
        }
    }

    // the name being spoken, in Daedric
    Row {
        id: nameRunes
        anchors.horizontalCenter: parent.horizontalCenter
        y: 496 * root.u
        spacing: 18 * root.u
        Rectangle { width: 90 * root.u; height: 1; color: root.cBrassLo; anchors.verticalCenter: parent.verticalCenter }
        Diamond { anchors.verticalCenter: parent.verticalCenter }
        Rune {
            text: nameField.text.toUpperCase().replace(/[^A-Z ]/g, "") || "NEREVARINE"
            font.pixelSize: 40 * root.u
            font.letterSpacing: 5 * root.u
        }
        Diamond { anchors.verticalCenter: parent.verticalCenter }
        Rectangle { width: 90 * root.u; height: 1; color: root.cBrassLo; anchors.verticalCenter: parent.verticalCenter }
    }

    // ---- login plate --------------------------------------------------------
    Plate {
        id: loginPlate
        width: 470 * root.u; height: 312 * root.u
        anchors.horizontalCenter: parent.horizontalCenter
        y: 570 * root.u
        transform: Translate { id: plateShift }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: plateShift; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: plateShift; property: "x"; to: 12;  duration: 90 }
            NumberAnimation { target: plateShift; property: "x"; to: -7;  duration: 80 }
            NumberAnimation { target: plateShift; property: "x"; to: 0;   duration: 70 }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 28 * root.u
            spacing: 12 * root.u

            // the greeting, in Daedric: one line per sentence
            Column {
                width: parent.width
                spacing: 4 * root.u
                Repeater {
                    model: (config.greeting || "You were dreaming. What is your name?").split(/[.?!]+/)
                    Rune {
                        readonly property string runes: modelData.toUpperCase().replace(/[^A-Z ]/g, "").trim()
                        visible: runes.length > 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: runes
                        font.pixelSize: 19 * root.u
                        font.letterSpacing: 2 * root.u
                        font.wordSpacing: 6 * root.u
                        fontSizeMode: Text.HorizontalFit; minimumPixelSize: 10
                    }
                }
            }
            Field {
                id: nameBox
                label: "Name"
                onAccepted: passField.forceActiveFocus()
            }
            Field {
                id: passBox
                label: "Password"
                secret: true
                onAccepted: root.doLogin()
            }
            Item {
                width: parent.width; height: 38 * root.u
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - enter.width - 12 * root.u
                    wrapMode: Text.WordWrap
                    text: root.loginPending ? "The gate opens…" : root.errorMsg
                    color: root.loginPending ? root.cBrassHi : root.cEmber
                    font.pixelSize: 14 * root.u
                }
                Button {
                    id: enter
                    anchors.right: parent.right
                    text: "Enter"
                    onClicked: root.doLogin()
                }
            }
        }
    }
    // session chooser
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 906 * root.u
        spacing: 14 * root.u
        visible: root.sessionNames.length > 0
        Label {
            text: "‹"; font.pixelSize: 22 * root.u; anchors.verticalCenter: parent.verticalCenter
            visible: root.sessionNames.length > 1
            MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleSession(-1) }
        }
        Label {
            text: root.sessionLabel; anchors.verticalCenter: parent.verticalCenter
            font.letterSpacing: 2 * root.u; color: root.cBone
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            text: "›"; font.pixelSize: 22 * root.u; anchors.verticalCenter: parent.verticalCenter
            visible: root.sessionNames.length > 1
            MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleSession(1) }
        }
    }

    // ---- footer -------------------------------------------------------------
    Column {
        x: root.width * 0.055 + 96 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 34 * root.u
        spacing: 2 * root.u
        Label { text: Qt.formatTime(root.now, "hh:mm"); font.pixelSize: 34 * root.u; color: root.cBone }
        Label { text: root.tamrielDate(root.now) }
    }

    Row {
        anchors.right: parent.right; anchors.rightMargin: root.width * 0.055 + 96 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 38 * root.u
        spacing: 14 * root.u
        Button { text: "Suspend";   visible: sddm.canSuspend;  onClicked: sddm.suspend() }
        Button { text: "Restart";   visible: sddm.canReboot;   onClicked: sddm.reboot() }
        Button { text: "Shut Down"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }
}
