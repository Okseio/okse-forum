# frozen_string_literal: true

require 'rails_helper'

describe TopicLinkSerializer do

  it "correctly serializes the topic link" do
    post = Fabricate(:post, raw: 'https://forum.okse.io/')
    TopicLink.extract_from(post)
    serialized = described_class.new(post.topic_links.first, root: false).as_json

    expect(serialized[:domain]).to eq("forum.okse.io")
    expect(serialized[:root_domain]).to eq("discourse.org")
  end
end
