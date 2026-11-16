#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define RING_CAPACITY 8

typedef struct {
    uint32_t items[RING_CAPACITY];
    size_t head;
    size_t len;
} ring_t;

static bool ring_push(ring_t *ring, uint32_t value) {
    if (ring->len == RING_CAPACITY) {
        return false;
    }
    ring->items[(ring->head + ring->len) % RING_CAPACITY] = value;
    ring->len++;
    return true;
}

static bool ring_pop(ring_t *ring, uint32_t *out) {
    if (ring->len == 0) return false;
    *out = ring->items[ring->head];
    ring->head = (ring->head + 1) % RING_CAPACITY;
    ring->len--;
    return true;
}

int main(void) {
    ring_t ring = {0};
    for (uint32_t i = 0; i < 10; i++) ring_push(&ring, i * i);
    uint32_t value;
    while (ring_pop(&ring, &value)) printf("%u\n", value);
    return 0;
}
