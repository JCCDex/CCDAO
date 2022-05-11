import Vue from 'vue'
import App from './App.vue'


import ElementUI from 'element-ui';
import 'element-ui/lib/theme-chalk/index.css';
import "./css/dialog.scss";
import i18n from './i18n'
Vue.use(ElementUI);3

Vue.config.productionTip = false

new Vue({
  i18n,
  render: h => h(App)
}).$mount('#app')
