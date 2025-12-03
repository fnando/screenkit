# frozen_string_literal: true

require "test_helper"

class HashTest < Minitest::Test
  using ScreenKit::CoreExt

  test "deep merges nil" do
    hash = {a: 1, b: {c: 2}}
    expected = {a: 1, b: {c: 2}}

    assert_equal expected, hash.deep_merge(nil)
    assert_equal expected, nil.deep_merge(hash)
  end

  test "overwrites key with different type" do
    hash1 = {a: 1, b: {c: 2}}
    hash2 = {b: 10}

    expected = {a: 1, b: 10}

    assert_equal expected, hash1.deep_merge(hash2)
  end

  test "merges two hashes deeply" do
    hash1 = {
      a: 1,
      b: {c: 2, d: 3},
      e: {f: {g: 4}}
    }

    hash2 = {
      b: {c: 20, x: 30},
      e: {f: {g: 40, h: 50}, i: 60},
      j: 70
    }

    expected = {
      a: 1,
      b: {c: 20, d: 3, x: 30},
      e: {f: {g: 40, h: 50}, i: 60},
      j: 70
    }

    assert_equal expected, hash1.deep_merge(hash2)
  end
end
