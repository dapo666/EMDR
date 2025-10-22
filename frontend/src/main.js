import Vue from 'vue';
import App from './App.vue';
import Controller from './Controller.vue';
import Menu from './Menu.vue';
import VueRouter from 'vue-router';

Vue.config.productionTip = false;
Vue.use(VueRouter);

const routes = [
  { path: '/', component: Menu },
  { path: '/patient', component: App },
  { path: '/controller', component: Controller }
];

const router = new VueRouter({
  mode: 'history',
  routes
});

new Vue({
  router,
  render: h => h('router-view'),
}).$mount('#app');
