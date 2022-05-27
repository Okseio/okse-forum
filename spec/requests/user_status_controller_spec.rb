# frozen_string_literal: true

describe UserStatusController do
  describe '#set' do
    it 'requires user to be logged in' do
      put "/user-status.json", params: { description: "off to dentist" }
      expect(response.status).to eq(403)
    end

    it "returns 404 if the feature is disabled" do
      user = Fabricate(:user)
      sign_in(user)
      SiteSetting.enable_user_status = false

      put "/user-status.json", params: { description: "off" }

      expect(response.status).to eq(404)
    end

    describe 'feature is enabled and user is logged in' do
      fab!(:user) { Fabricate(:user) }

      before do
        sign_in(user)
        SiteSetting.enable_user_status = true
      end

      it 'the description parameter is mandatory' do
        put "/user-status.json", params: { emoji: "tooth" }
        expect(response.status).to eq(400)
      end

      it 'the emoji parameter is mandatory' do
        put "/user-status.json", params: { description: "off to dentist" }
        expect(response.status).to eq(400)
      end

      it "sets user status" do
        status = "off to dentist"
        status_emoji = "tooth"
        put "/user-status.json", params: { description: status, emoji: status_emoji }
        expect(user.user_status.description).to eq(status)
        expect(user.user_status.emoji).to eq(status_emoji)
      end

      it "following calls update status" do
        status = "off to dentist"
        status_emoji = "tooth"
        put "/user-status.json", params: { description: status }
        user.reload
        expect(user.user_status.description).to eq(status)
        expect(user.user_status.emoji).to eq(status_emoji)

        new_status = "surfing"
        new_status_emoji = "surfing_man"
        put "/user-status.json", params: { description: new_status }
        user.reload
        expect(user.user_status.description).to eq(new_status)
        expect(user.user_status.emoji).to eq(new_status_emoji)
      end
    end
  end

  describe '#clear' do
    it 'requires you to be logged in' do
      delete "/user-status.json"
      expect(response.status).to eq(403)
    end

    it "returns 404 if the feature is disabled" do
      user = Fabricate(:user)
      sign_in(user)
      SiteSetting.enable_user_status = false

      delete "/user-status.json"

      expect(response.status).to eq(404)
    end

    describe 'feature is enabled and user is logged in' do
      fab!(:user_status) { Fabricate(:user_status, description: "off to dentist") }
      fab!(:user) { Fabricate(:user, user_status: user_status) }

      before do
        sign_in(user)
        SiteSetting.enable_user_status = true
      end

      it "clears user status" do
        delete "/user-status.json"

        user.reload
        expect(user.user_status).to be_nil
      end
    end
  end
end
