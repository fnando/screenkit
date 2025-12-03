require "test_helper"

class JsonTest < Minitest::Test
  using ScreenKit::CoreExt

  test "transforms pathname" do
    assert_equal "/foo", Pathname("/foo").as_json
  end

  test "transforms hash" do
    obj = { path: Pathname("/foo"), name: "bar" }
    expected = { path: "/foo", name: "bar" }

    assert_equal expected, obj.as_json
  end

  test "transforms array" do
    obj = [Pathname("/foo"), Pathname("/bar")]
    expected = ["/foo", "/bar"]

    assert_equal expected, obj.as_json
  end
end
