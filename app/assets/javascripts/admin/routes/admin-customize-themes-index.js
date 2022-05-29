import Route from "@ember/routing/route";
import { emojiUrlFor } from "discourse/lib/text";

const externalResources = [
  {
    key: "admin.customize.theme.beginners_guide_title",
    link: "https://forum.okse.io/t/91966",
    icon: "book"
  },
  {
    key: "admin.customize.theme.developers_guide_title",
    link: "https://forum.okse.io/t/93648",
    icon: "book"
  },
  {
    key: "admin.customize.theme.browse_themes",
    link: "https://forum.okse.io/c/theme",
    icon: "paint-brush"
  }
];

export default Route.extend({
  setupController(controller) {
    this._super(...arguments);
    this.controllerFor("adminCustomizeThemes").set("editingTheme", false);
    controller.setProperties({
      externalResources,
      womanArtistEmojiURL: emojiUrlFor("woman_artist:t5")
    });
  }
});
