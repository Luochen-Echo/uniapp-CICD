<script setup>
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import TabBar from '@/components/TabBar.vue'

const route = useRoute()
const userStore = useUserStore()

// 判断是否显示TabBar
const showTabBar = computed(() => {
  const tabBarRoutes = ['Home', 'Calendar', 'Profile']
  return tabBarRoutes.includes(route.name)
})

// 应用初始化时加载用户信息
onMounted(async () => {
  const token = localStorage.getItem('token')
  if (token && !userStore.userInfo) {
    try {
      await userStore.fetchUserInfo()
      console.log('App - 用户信息已加载')
    } catch (error) {
      console.error('App - 加载用户信息失败:', error)
    }
  }
})
</script>

<template>
  <div id="app">
    <router-view class="page-content" :class="{ 'with-tabbar': showTabBar }" />
    <TabBar v-if="showTabBar" />
  </div>
</template>

<style lang="scss">
#app {
  width: 100%;
  min-height: 100vh;
  background-color: #f5f6f7;
}

.page-content {
  min-height: 100vh;
  padding-bottom: 0;

  &.with-tabbar {
    padding-bottom: calc(50px + constant(safe-area-inset-bottom));
    padding-bottom: calc(50px + env(safe-area-inset-bottom));
  }
}
</style>
