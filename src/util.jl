"""
Radius of the Earth
"""
const R = 6371000

"""
ground distance
"""
function dG(lat1, lon1, lat2, lon2; r = R)
    φi, λi = deg2rad(lat1), deg2rad(lon1)
    φj, λj = deg2rad(lat2), deg2rad(lon2)
    v1 = sin((φj - φi) / 2)
    v2 = sin((λj - λi) / 2)
    return 2 * r * asin(sqrt(v1^2 + cos(φi) * cos(φj) * v2^2))
end