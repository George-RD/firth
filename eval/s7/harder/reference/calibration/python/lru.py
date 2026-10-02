from collections import OrderedDict


def main(cap, keys):
    cache, misses = OrderedDict(), 0
    for k in keys:
        if k in cache:
            cache.move_to_end(k)
            continue
        misses += 1
        if len(cache) >= cap:
            cache.popitem(last=False)
        cache[k] = True
    return misses, list(cache)
