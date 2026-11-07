#include "coverflowtransform.h"
#include <QtMath>

static qreal easeOutPower(qreal distance, qreal power)
{
    const qreal a = qMin(qAbs(distance), 1.0);
    const qreal progress = 1.0 - qPow(1.0 - a, power);
    return distance < 0 ? -progress : progress;
}

CoverFlowTransform::CoverFlowTransform(QQuickItem *parent)
    : QQuickTransform(parent)
{
}

void CoverFlowTransform::setDistance(qreal v) { if (m_distance != v) { m_distance = v; update(); emit changed(); } }
void CoverFlowTransform::setCard(qreal v) { if (m_card != v) { m_card = v; update(); emit changed(); } }
void CoverFlowTransform::setAngle(qreal v) { if (m_angle != v) { m_angle = v; update(); emit changed(); } }
void CoverFlowTransform::setPerspective(qreal v) { if (m_perspective != v) { m_perspective = v; update(); emit changed(); } }
void CoverFlowTransform::setHandoffPower(qreal v) { if (m_handoffPower != v) { m_handoffPower = v; update(); emit changed(); } }

void CoverFlowTransform::applyTo(QMatrix4x4 *matrix) const
{
    const qreal eased = easeOutPower(m_distance, m_handoffPower);
    const qreal clamped = qBound(-1.0, m_distance, 1.0);
    const qreal centerPush = m_card * 0.66;
    const qreal stackSpacing = m_card * 0.2;
    const qreal translateX = eased * centerPush + (m_distance - clamped) * stackSpacing;
    const qreal rotateY = -eased * m_angle;
    const qreal scale = 1.0 - qAbs(eased) * 0.12;

    QMatrix4x4 m;
    m.translate(m_card / 2.0, m_card / 2.0);
    QMatrix4x4 p;
    p(3, 2) = -1.0 / m_perspective;
    m *= p;
    m.translate(translateX, 0.0, 0.0);
    m.rotate(rotateY, 0.0, 1.0, 0.0);
    m.scale(scale, scale, 1.0);
    m.translate(-m_card / 2.0, -m_card / 2.0);
    *matrix *= m;
}
