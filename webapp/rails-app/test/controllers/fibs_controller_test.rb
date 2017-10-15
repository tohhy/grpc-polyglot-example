require 'test_helper'

class FibsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fib = fibs(:one)
  end

  test "should get index" do
    get fibs_url
    assert_response :success
  end

  test "should get new" do
    get new_fib_url
    assert_response :success
  end

  test "should create fib" do
    assert_difference('Fib.count') do
      post fibs_url, params: { fib: {  } }
    end

    assert_redirected_to fib_url(Fib.last)
  end

  test "should show fib" do
    get fib_url(@fib)
    assert_response :success
  end

  test "should get edit" do
    get edit_fib_url(@fib)
    assert_response :success
  end

  test "should update fib" do
    patch fib_url(@fib), params: { fib: {  } }
    assert_redirected_to fib_url(@fib)
  end

  test "should destroy fib" do
    assert_difference('Fib.count', -1) do
      delete fib_url(@fib)
    end

    assert_redirected_to fibs_url
  end
end
