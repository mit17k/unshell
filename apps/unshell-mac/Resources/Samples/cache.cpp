#include <list>
#include <optional>
#include <string>
#include <unordered_map>

template <typename Key, typename Value>
class LruCache {
public:
    explicit LruCache(std::size_t capacity) : capacity_(capacity) {}

    std::optional<Value> get(const Key& key) {
        auto it = index_.find(key);
        if (it == index_.end()) return std::nullopt;
        order_.splice(order_.begin(), order_, it->second);
        return it->second->second;
    }

    void put(Key key, Value value) {
        if (auto it = index_.find(key); it != index_.end()) {
            order_.erase(it->second);
        } else if (order_.size() == capacity_) {
            index_.erase(order_.back().first);
            order_.pop_back();
        }
        order_.emplace_front(std::move(key), std::move(value));
        index_[order_.front().first] = order_.begin();
    }

private:
    using Entry = std::pair<Key, Value>;
    std::size_t capacity_;
    std::list<Entry> order_;
    std::unordered_map<Key, typename std::list<Entry>::iterator> index_;
};

int main() {
    LruCache<std::string, int> cache{2};
    cache.put("a", 1);
    return cache.get("a").value_or(0) == 1 ? 0 : 1;
}
