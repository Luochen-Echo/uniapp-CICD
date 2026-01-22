<template>
  <div class="login-page">
    <div class="login-container">
      <!-- Logo区域 -->
      <div class="logo-section">
        <div class="logo-icon">📝</div>
        <div class="logo-title">工作日志</div>
        <div class="logo-subtitle">记录每一天的工作与成长</div>
      </div>

      <!-- 登录表单 -->
      <van-form @submit="handleLogin" class="login-form">
        <!-- 用户名输入 -->
        <div class="form-item">
          <span class="input-icon">👤</span>
          <van-field
            v-model="username"
            name="username"
            placeholder="请输入用户名"
            :rules="[{ required: true, message: '请输入用户名' }]"
            border={false}
            class="form-input"
          />
        </div>

        <!-- 密码输入 -->
        <div class="form-item">
          <span class="input-icon">🔒</span>
          <van-field
            v-model="password"
            type="password"
            name="password"
            placeholder="请输入密码"
            :rules="[{ required: true, message: '请输入密码' }]"
            border={false}
            class="form-input"
          />
        </div>

        <!-- 登录按钮 -->
        <van-button
          round
          block
          type="primary"
          native-type="submit"
          :loading="loading"
          loading-text="登录中..."
          class="login-btn"
        >
          {{ loading ? '登录中...' : '登录' }}
        </van-button>
      </van-form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { showToast } from 'vant'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

// 表单数据
const username = ref('')
const password = ref('')
const loading = ref(false)

// 登录处理
const handleLogin = async () => {
  if (loading.value) return

  loading.value = true

  try {
    // 调用登录接口
    await userStore.login(username.value, password.value)

    showToast({
      message: '登录成功',
      duration: 1500
    })

    // 跳转到主页或重定向页面
    const redirect = route.query.redirect || '/home'
    setTimeout(() => {
      router.replace(redirect)
    }, 1000)
  } catch (error) {
    console.error('登录失败:', error)
    // 错误提示已在拦截器中处理
  } finally {
    loading.value = false
  }
}
</script>

<style lang="scss" scoped>
.login-page {
  min-height: 100vh;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 30px;
}

.login-container {
  width: 100%;
  max-width: 400px;
}

/* Logo区域 */
.logo-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 60px;
}

.logo-icon {
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #3370FF, #5B8FFF);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36px;
  margin-bottom: 16px;
  box-shadow: 0 4px 12px rgba(51, 112, 255, 0.2);
}

.logo-title {
  font-size: 24px;
  font-weight: 600;
  color: #1F2329;
  margin-bottom: 8px;
}

.logo-subtitle {
  font-size: 14px;
  color: #8F959E;
}

/* 登录表单 */
.login-form {
  width: 100%;
}

.form-item {
  display: flex;
  align-items: center;
  background: #F5F6F7;
  border-radius: 8px;
  padding: 0 16px;
  margin-bottom: 12px;
  height: 48px;
  transition: all 0.3s;

  &:focus-within {
    background: #EBECF0;
  }
}

.input-icon {
  font-size: 18px;
  margin-right: 12px;
  opacity: 0.6;
}

:deep(.form-input) {
  flex: 1;
  background: transparent;
  padding: 0;
  font-size: 15px;
  color: #1F2329;
}

:deep(.form-input .van-field__control) {
  color: #1F2329;
}

:deep(.form-input .van-field__control::placeholder) {
  color: #8F959E;
}

/* 登录按钮 */
.login-btn {
  width: 100%;
  height: 48px;
  background: linear-gradient(135deg, #3370FF, #5B8FFF);
  border-radius: 8px;
  border: none;
  font-size: 17px;
  font-weight: 600;
  margin-top: 24px;
  box-shadow: 0 4px 12px rgba(51, 112, 255, 0.3);
}

.login-btn:active {
  opacity: 0.9;
  transform: scale(0.98);
}
</style>
