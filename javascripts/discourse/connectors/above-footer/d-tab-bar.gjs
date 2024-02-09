/* eslint ember/no-private-routing-service: 0 */
import and from "truth-helpers/helpers/and";
import cookie from "discourse/lib/cookie";
import eq from "truth-helpers/helpers/eq";
import not from "truth-helpers/helpers/not";
import Component from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { inject as service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import discourseURL from "discourse/lib/url";
import dIcon from "discourse-common/helpers/d-icon";
import { parseTabsSettings, routeToURL } from "../../../d-tab-bar/lib/helpers";
import concatClass from "discourse/helpers/concat-class";
import ChatHeaderIconUnreadIndicator from "discourse/plugins/chat/discourse/components/chat/header/icon/unread-indicator";

const SCROLL_MAX = 30;
const HIDDEN_TAB_BAR_CLASS = "tab-bar-hidden";

export default class DTabBar extends Component {
  @service router;
  @service currentUser;
  @service site;

  tabs = parseTabsSettings();
  lastScrollTop = 0;

  get width() {
    const length = this.tabs.length;
    const percentage = length ? 100 / length : length;
    return htmlSafe(`width: ${percentage}%;`);
  }

  scrollListener() {
    const scrollTop = window.scrollY;
    const body = document.body;
    if (
      this.lastScrollTop < scrollTop &&
      scrollTop > SCROLL_MAX &&
      !body.classList.contains(HIDDEN_TAB_BAR_CLASS)
    ) {
      body.classList.add(HIDDEN_TAB_BAR_CLASS);
    } else if (
      this.lastScrollTop > scrollTop &&
      body.classList.contains(HIDDEN_TAB_BAR_CLASS)
    ) {
      body.classList.remove(HIDDEN_TAB_BAR_CLASS);
    }
    this.lastScrollTop = scrollTop;
  }

  @action
  navigate(tab) {
    if (!tab.anonymous && !this.currentUser) {
      cookie("destination_url", tab.destination);
      return this.router.replaceWith("login");
    }
    const destination = tab.destination;
    let url = destination;
    if (this.router._router.hasRoute(destination)) {
      url = routeToURL(this.router._router, destination, this.currentUser);
    }
    discourseURL.routeTo(url);
  }

  @action
  setupScrollListener() {
    document.addEventListener("scroll", this.scrollListener);
  }

  @action
  removeScrollListener() {
    document.removeEventListener("scroll", this.scrollListener);
  }

  <template>
    {{#if (and this.site.mobileView this.tabs.length)}}
      <div
        class="d-tab-bar"
        {{didInsert this.setupScrollListener}}
        {{willDestroy this.removeScrollListener}}
      >
        {{#each this.tabs as |tab|}}
          <div
            role="link"
            style={{this.width}}
            class={{concatClass
              (if (eq tab.destination "chat") "tab tab-chat" "tab")
              (if (and (not tab.anonymous) (not this.currentUser)) "tab--disabled" "")
            }}
            data-destination={{tab.destination}}
            {{on "click" (fn this.navigate tab)}}
          >
            <span class="icon">
              {{dIcon tab.icon}}
              {{#if (eq tab.destination "chat")}}
                <ChatHeaderIconUnreadIndicator />
              {{/if}}
            </span>
            {{#if settings.display_icon_titles}}
              <p class="title">{{tab.title}}</p>
            {{/if}}
          </div>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
