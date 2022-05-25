import Vue from "vue";
import ElementUI from "element-ui";

import VueI18n from "vue-i18n";

Vue.use(ElementUI);

Vue.config.productionTip = false;
Vue.use(VueI18n);

const messages = {
  en: {
    message: require("./locales/en"),
  },
};

const i18n = new VueI18n({
  locale: "en",
  messages,
});

const render = ({ component }) => {
  const v = new Vue({
    i18n,
    render(createElement) {
      return createElement(component);
    },
  });

  return v;
};

export default render;
