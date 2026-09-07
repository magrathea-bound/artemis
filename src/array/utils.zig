
pub fn calc_cap(bytes: usize) usize {
    var capacity: usize = 64;
    while (capacity < bytes) {
        capacity *= 2;
    }
    return capacity;
}
