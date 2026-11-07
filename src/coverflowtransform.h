#ifndef COVERFLOWTRANSFORM_H
#define COVERFLOWTRANSFORM_H

#include <QQuickTransform>
#include <QMatrix4x4>

// Cover Flow transform after rit3zh/expo-coverflow-carousel:
//   distance  = index - scrollOffset
//   eased     = sign(distance) * (1 - (1 - min(|distance|,1))^power)
//   translateX = eased*centerPush + (distance - clamp(distance,-1,1))*stackSpacing
//   rotateY    = -eased * angle
//   scale      = 1 - |eased|*0.12
//   transform  = perspective(1000) * translateX * rotateY * scale
class CoverFlowTransform : public QQuickTransform
{
    Q_OBJECT
    Q_PROPERTY(qreal distance READ distance WRITE setDistance NOTIFY changed)
    Q_PROPERTY(qreal card READ card WRITE setCard NOTIFY changed)
    Q_PROPERTY(qreal angle READ angle WRITE setAngle NOTIFY changed)
    Q_PROPERTY(qreal perspective READ perspective WRITE setPerspective NOTIFY changed)
    Q_PROPERTY(qreal handoffPower READ handoffPower WRITE setHandoffPower NOTIFY changed)

public:
    explicit CoverFlowTransform(QQuickItem *parent = nullptr);

    qreal distance() const { return m_distance; }
    qreal card() const { return m_card; }
    qreal angle() const { return m_angle; }
    qreal perspective() const { return m_perspective; }
    qreal handoffPower() const { return m_handoffPower; }

    void setDistance(qreal v);
    void setCard(qreal v);
    void setAngle(qreal v);
    void setPerspective(qreal v);
    void setHandoffPower(qreal v);

    void applyTo(QMatrix4x4 *matrix) const override;

signals:
    void changed();

private:
    qreal m_distance = 0.0;
    qreal m_card = 260.0;
    qreal m_angle = 64.0;
    qreal m_perspective = 1000.0;
    qreal m_handoffPower = 1.29;
};

#endif // COVERFLOWTRANSFORM_H
