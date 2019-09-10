# frozen_string_literal: true

describe CondaAPI do
  it "should show HelloWorld" do
    get "/"
    expect(last_response).to be_ok
  end
end
