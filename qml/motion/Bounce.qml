pragma ComponentBehavior: Bound
import QtQuick

// a quick, damped settle for press and hover states. it keeps a soft spring
// response without the repeated bounce that made small controls feel wobbly.
SpringAnimation {
    spring: 8
    damping: 0.58
    epsilon: 0.004
}
