<template>
  <div class="profile-page">
    <!-- 导航栏占位 -->
    <div class="navbar-placeholder"></div>

    <!-- 用户信息卡片 -->
    <div class="user-card">
      <div class="user-avatar">
        <img
          class="avatar-img"
          :src="userInfo.avatar || '/default-avatar.png'"
          alt="头像"
        />
      </div>
      <div class="user-info">
        <div class="user-name">{{ userInfo.nickName || userInfo.userName || '未设置昵称' }}</div>
        <div class="user-role" v-if="userInfo.dept">
          {{ userInfo.dept.deptName || '未知部门' }}
        </div>
      </div>
      <div class="edit-icon">✏️</div>
    </div>

    <!-- 功能菜单 -->
    <div class="menu-section">
      <div class="menu-item" @click="goToEdit">
        <div class="menu-left">
          <span class="menu-icon">👤</span>
          <div class="menu-label">个人资料</div>
        </div>
        <div class="menu-arrow">›</div>
      </div>

      <div class="menu-item" @click="goToPassword">
        <div class="menu-left">
          <span class="menu-icon">🔒</span>
          <div class="menu-label">修改密码</div>
        </div>
        <div class="menu-arrow">›</div>
      </div>

      <div class="menu-item" @click="goToSettings">
        <div class="menu-left">
          <span class="menu-icon">⚙️</span>
          <div class="menu-label">系统设置</div>
        </div>
        <div class="menu-arrow">›</div>
      </div>
    </div>

    <!-- 退出登录按钮 -->
    <div class="logout-section">
      <button class="logout-btn" @click="handleLogout">退出登录</button>
    </div>

    <!-- 版本信息 -->
    <div class="version-info">
      <span>工作日志 v1.0.0</span>
    </div>

    <!-- 底部安全区 -->
    <div class="safe-area"></div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { showDialog, showToast } from 'vant'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

// 用户信息
const userInfo = ref({})

onMounted(() => {
  loadUserInfo()
})

// 加载用户信息
function loadUserInfo() {
  // 从store获取
  if (userStore.userInfo) {
    userInfo.value = userStore.userInfo
  }

  // 刷新获取最新数据
  userStore.fetchUserInfo().then(res => {
    userInfo.value = res.user
  }).catch(err => {
    console.error('获取用户信息失败:', err)
  })
}

// 跳转到编辑资料
function goToEdit() {
  showToast('功能开发中...')
}

// 跳转到修改密码
function goToPassword() {
  showToast('功能开发中...')
}

// 跳转到系统设置
function goToSettings() {
  showToast('功能开发中...')
}

// 退出登录
function handleLogout() {
  showDialog({
    title: '提示',
    message: '确定要退出登录吗？',
    confirmButtonColor: '#F54A45',
    showCancelButton: true
  }).then(() => {
    userStore.logout()
    router.replace('/login')
  }).catch(() => {
    // 用户取消
  })
}
</script>

<style lang="scss" scoped>
.profile-page {
  min-height: 100vh;
  background: #F5F6F7;
  padding-bottom: 50px;
}

/* 导航栏占位 */
.navbar-placeholder {
  height: 56px;
  background: #F5F6F7;
}

/* 用户信息卡片 */
.user-card {
  background: #FFFFFF;
  margin: 16px;
  padding: 24px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.user-avatar {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  overflow: hidden;
  background: #E8F3FF;
  flex-shrink: 0;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.user-info {
  flex: 1;
}

.user-name {
  font-size: 18px;
  font-weight: 600;
  color: #1F2329;
  margin-bottom: 6px;
}

.user-role {
  font-size: 14px;
  color: #8F959E;
}

.edit-icon {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  color: #8F959E;
  cursor: pointer;
}

/* 功能菜单 */
.menu-section {
  background: #FFFFFF;
  margin: 0 16px 16px;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.menu-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  border-bottom: 1px solid #E4E7ED;
  cursor: pointer;

  &:last-child {
    border-bottom: none;
  }

  &:active {
    background: #F5F6F7;
  }
}

.menu-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.menu-icon {
  width: 24px;
  height: 24px;
  font-size: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.menu-label {
  font-size: 15px;
  color: #1F2329;
}

.menu-arrow {
  font-size: 20px;
  color: #C8C9CC;
  font-weight: 300;
}

/* 退出登录按钮 */
.logout-section {
  padding: 0 16px;
}

.logout-btn {
  width: 100%;
  height: 48px;
  background: #FFFFFF;
  border: none;
  border-radius: 12px;
  color: #F54A45;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);

  &:active {
    background: #FFF0F0;
  }
}

/* 版本信息 */
.version-info {
  text-align: center;
  padding: 24px;
  font-size: 12px;
  color: #C8C9CC;
}

/* 底部安全区 */
.safe-area {
  height: 34px;
}
</style>
