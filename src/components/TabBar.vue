<template>
  <div class="custom-tab-bar">
    <div
      v-for="(item, index) in tabList"
      :key="index"
      class="tab-bar-item"
      :class="{ active: currentIndex === index }"
      @click="switchTab(index)"
    >
      <div class="tab-icon">
        <slot name="icon" :index="index" :active="currentIndex === index">
          <!-- 默认图标 -->
          <span class="default-icon">{{ item.text.charAt(0) }}</span>
        </slot>
      </div>
      <div class="tab-text">{{ item.text }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

// Tab配置
const tabList = [
  { pagePath: '/home', text: '日志' },
  { pagePath: '/calendar', text: '日历' },
  { pagePath: '/profile', text: '我的' }
]

// 当前选中的Tab索引
const currentIndex = ref(0)

// 根据路由计算当前索引
const getCurrentIndex = () => {
  const path = route.path
  const index = tabList.findIndex(item => path.startsWith(item.pagePath))
  return index >= 0 ? index : 0
}

// 监听路由变化更新索引
watch(
  () => route.path,
  () => {
    currentIndex.value = getCurrentIndex()
  },
  { immediate: true }
)

// 切换Tab
const switchTab = (index) => {
  if (currentIndex.value === index) return

  currentIndex.value = index
  router.replace(tabList[index].pagePath)
}
</script>

<style lang="scss" scoped>
.custom-tab-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  background: #fff;
  border-top: 1px solid var(--border-color);
  padding-bottom: constant(safe-area-inset-bottom);
  padding-bottom: env(safe-area-inset-bottom);
  z-index: 1000;
}

.tab-bar-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 50px;
  color: var(--text-color-secondary);
  transition: color 0.3s;

  &.active {
    color: var(--primary-color);
  }

  &:active {
    background-color: #f5f6f7;
  }
}

.tab-icon {
  margin-bottom: 2px;

  .default-icon {
    display: inline-block;
    width: 22px;
    height: 22px;
    line-height: 22px;
    text-align: center;
    font-size: 12px;
    border: 2px solid currentColor;
    border-radius: 4px;
  }
}

.tab-text {
  font-size: 10px;
  line-height: 1.2;
}
</style>
