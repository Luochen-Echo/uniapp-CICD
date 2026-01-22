<template>
  <div class="user-list-page">
    <!-- 导航栏 -->
    <van-nav-bar title="选择用户" left-arrow @click-left="onClickLeft" />

    <!-- 部门列表 -->
    <div class="dept-list">
      <!-- 加载状态 -->
      <div class="loading-state" v-if="loading">
        <van-loading size="24px">加载中...</van-loading>
      </div>

      <!-- 部门分组 -->
      <div class="dept-group" v-for="dept in deptGroups" :key="dept.deptId">
        <!-- 部门标题 -->
        <div class="dept-header" @click="toggleDept(dept.deptId)">
          <div class="dept-info">
            <div class="dept-arrow" :class="{ expanded: expandedDepts[dept.deptId] }">›</div>
            <div class="dept-name">{{ dept.deptName }}</div>
            <div class="dept-count">({{ dept.users.length }}人)</div>
          </div>
        </div>

        <!-- 用户列表（展开时显示） -->
        <div class="user-list-container" v-if="expandedDepts[dept.deptId]">
          <div class="user-list">
            <div
              class="user-item"
              v-for="user in dept.users"
              :key="user.userId"
              @click="selectUser(user)"
            >
              <div class="user-avatar">
                <span class="avatar-text">{{ user.userName ? user.userName.charAt(0) : 'U' }}</span>
              </div>
              <div class="user-info">
                <div class="user-name">{{ user.userName }}</div>
                <div class="user-role" v-if="user.remark">{{ user.remark }}</div>
              </div>
              <div class="user-arrow">›</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <div class="empty-state" v-if="!loading && deptGroups.length === 0">
        <van-empty description="暂无用户" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { showToast } from 'vant'
import { getUserList } from '@/api'
import { useLogStore } from '@/stores/log'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const logStore = useLogStore()
const userStore = useUserStore()

// 数据
const allUsers = ref([])
const deptGroups = ref([])
const expandedDepts = ref({})
const loading = ref(false)
const loaded = ref(false)

// 当前正在查看的用户ID（需要过滤掉）
const currentUserId = computed(() => {
  return logStore.viewingUserId || userStore.userInfo?.userId
})

onMounted(() => {
  console.log('UserList - 当前正在查看的用户ID:', currentUserId.value)
  loadUserList()
})

// 返回上一页
function onClickLeft() {
  router.back()
}

// 加载用户列表
function loadUserList() {
  if (loaded.value) {
    return
  }

  loading.value = true

  getUserList({
    pageNum: 1,
    pageSize: 100
  })
    .then(res => {
      const users = res.rows || []
      allUsers.value = users

      // 过滤掉当前正在查看的用户
      const filteredUsers = filterCurrentUser(users)
      console.log('过滤后的用户列表:', filteredUsers)

      // 按部门分组
      const groups = groupByDept(filteredUsers)
      deptGroups.value = groups

      // 默认展开第一个部门
      if (groups.length > 0) {
        expandedDepts.value[groups[0].deptId] = true
      }

      loaded.value = true
    })
    .catch(err => {
      console.error('加载用户列表失败:', err)
      showToast('加载失败')
    })
    .finally(() => {
      loading.value = false
    })
}

// 过滤掉当前正在查看的用户
function filterCurrentUser(users) {
  if (!currentUserId.value) {
    return users
  }
  return users.filter(user => user.userId !== currentUserId.value)
}

// 按部门分组
function groupByDept(users) {
  const deptMap = new Map()

  users.forEach(user => {
    if (!user.dept) return

    const deptId = user.dept.deptId
    const deptName = user.dept.deptName || '未分组'

    if (!deptMap.has(deptId)) {
      deptMap.set(deptId, {
        deptId,
        deptName,
        users: []
      })
    }

    deptMap.get(deptId).users.push(user)
  })

  return Array.from(deptMap.values())
}

// 切换部门展开/收起
function toggleDept(deptId) {
  expandedDepts.value[deptId] = !expandedDepts.value[deptId]
}

// 选择用户
function selectUser(user) {
  // 设置查看的用户
  logStore.setViewingUser(user.userId, user.userName)

  showToast(`已切换到${user.userName}的日志`)

  // 跳转到日历页面
  setTimeout(() => {
    router.replace('/calendar')
  }, 500)
}
</script>

<style lang="scss" scoped>
.user-list-page {
  min-height: 100vh;
  background: #F5F6F7;
}

/* 部门列表 */
.dept-list {
  padding: 16px;
}

/* 加载状态 */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #8F959E;
}

/* 部门分组 */
.dept-group {
  background: #FFFFFF;
  border-radius: 12px;
  margin-bottom: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.dept-header {
  padding: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  border-bottom: 1px solid #E4E7ED;

  &:active {
    background: #F5F6F7;
  }
}

.dept-info {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.dept-arrow {
  font-size: 18px;
  color: #646A73;
  transition: transform 0.3s;

  &.expanded {
    transform: rotate(90deg);
  }
}

.dept-name {
  font-size: 16px;
  font-weight: 600;
  color: #1F2329;
}

.dept-count {
  font-size: 13px;
  color: #8F959E;
}

/* 用户列表 */
.user-list {
  padding: 0 16px 16px;
}

.user-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid #E4E7ED;
  cursor: pointer;

  &:last-child {
    border-bottom: none;
  }

  &:active {
    background: #F5F6F7;
    margin: 0 -16px;
    padding: 12px 16px;
  }
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3370FF, #5B8FFF);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.avatar-text {
  color: #FFFFFF;
  font-size: 16px;
  font-weight: 600;
}

.user-info {
  flex: 1;
}

.user-name {
  font-size: 15px;
  font-weight: 500;
  color: #1F2329;
  margin-bottom: 4px;
}

.user-role {
  font-size: 12px;
  color: #8F959E;
}

.user-arrow {
  font-size: 18px;
  color: #C8C9CC;
  font-weight: 300;
}

/* 空状态 */
.empty-state {
  padding: 60px 20px;
}
</style>
