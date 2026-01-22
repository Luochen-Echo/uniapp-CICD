# DayUniApp H5 项目执行指南

## 项目概述

这是一个将微信小程序转换为移动端H5 Web应用的项目，使用Vue 3 + Vite技术栈。

**技术栈**: Vue 3 + Vite + Vue Router + Pinia + Vant + Axios
**项目路径**: `/Users/servert/PycharmProjects/dayuniapp/dayuniapp-h5`

---

## 已完成的工作

### ✅ 阶段一：项目基础搭建（已完成）

1. **创建Vue 3项目**
   - 使用Vite创建项目
   - 安装核心依赖：Vue Router 4、Pinia、Vant 4、Axios、Sass

2. **项目结构**
   ```
   dayuniapp-h5/
   ├── src/
   │   ├── api/              # API接口封装 ✅
   │   │   ├── request.js    # Axios配置
   │   │   └── index.js      # 所有API接口
   │   ├── stores/           # Pinia状态管理 ✅
   │   │   ├── user.js       # 用户状态
   │   │   └── log.js        # 日志状态
   │   ├── router/           # Vue Router配置 ✅
   │   │   └── index.js      # 路由配置
   │   ├── views/            # 页面组件
   │   │   └── Login.vue     # 登录页 ✅
   │   ├── components/       # 公共组件
   │   │   └── TabBar.vue    # 底部导航 ✅
   │   ├── styles/           # 全局样式 ✅
   │   │   └── index.scss    # 全局样式和移动端适配
   │   ├── App.vue           # 根组件 ✅
   │   └── main.js           # 入口文件 ✅
   ├── .env.development      # 开发环境变量 ✅
   ├── .env.production       # 生产环境变量 ✅
   └── vite.config.js        # Vite配置 ✅
   ```

3. **核心配置**
   - ✅ Axios请求封装（基于小程序request.js改造）
   - ✅ 路由配置（包含路由守卫和认证检查）
   - ✅ Pinia状态管理（User和Log两个store）
   - ✅ 全局样式和移动端适配（安全区域、rpx转换）
   - ✅ Vite开发和打包配置（路径别名、代理、代码分割）

4. **已创建页面**
   - ✅ 登录页面（Login.vue）
   - ✅ TabBar组件（TabBar.vue）

---

## 下一步工作

### 阶段二：页面迁移（进行中）

#### 页面1：日志主页（Home.vue）⏳

**参考文件**: 小程序 `pages/index/`

**功能要求**:
- 周视图日志列表（显示7天）
- 周选择器（上一周/下一周/回到本周）
- 工作日统计（工作天数、总日志数、待填写天数）
- 快速添加/编辑/删除日志
- 查看他人日志功能（管理员权限）
- 返回我的日志按钮

**数据来源**:
- API: `getWeekLogs(startDate)`
- Store: `useLogStore().weekLogs`
- 计算属性: `useLogStore().workStats`

**页面结构**:
```vue
<template>
  <div class="home-page">
    <!-- 头部：用户信息 + 统计 -->
    <HeaderBar :stats="workStats" />

    <!-- 周选择器 -->
    <WeekSelector @previous="previousWeek" @next="nextWeek" @back="backToThisWeek" />

    <!-- 日志列表 -->
    <LogList :logs="weekLogs" :dates="weekDates" />

    <!-- 浮动添加按钮 -->
    <van-floating-button @click="addLog" />

    <!-- 查看他人日志按钮（管理员） -->
    <ViewUserButton v-if="isAdmin" @click="goToUserList" />

    <!-- 返回我的日志（当查看他人日志时） -->
    <BackButton v-if="viewingUser" @click="backToMyLogs" />
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useLogStore } from '@/stores/log'
import { useUserStore } from '@/stores/user'
import { useRouter } from 'vue-router'

const logStore = useLogStore()
const userStore = useUserStore()
const router = useRouter()

const weekLogs = computed(() => logStore.weekLogs)
const workStats = computed(() => logStore.workStats)
const isAdmin = computed(() => userStore.isAdmin)

onMounted(() => {
  logStore.backToThisWeek()
})

function previousWeek() {
  logStore.previousWeek()
}

function nextWeek() {
  logStore.nextWeek()
}

function backToThisWeek() {
  logStore.backToThisWeek()
}

function addLog() {
  router.push('/log')
}

function goToUserList() {
  router.push('/users')
}

function backToMyLogs() {
  logStore.clearViewingUser()
  logStore.backToThisWeek()
}

function editLog(logId) {
  router.push(`/log/${logId}`)
}

function deleteLog(logId) {
  // 确认后调用API删除
}
</script>
```

**预计时间**: 1.5小时

---

#### 页面2：日历页面（Calendar.vue）⏳

**参考文件**: 小程序 `pages/calendar/`

**功能要求**:
- 月历展示（42天布局，6行7列）
- 日期标记（有日志的日期显示标记点）
- 月份切换（上一月/下一月）
- 点击日期查看/添加日志
- 查看他人月度日志（管理员权限）

**核心逻辑**:
```javascript
// 生成42天日历
function generateCalendar(year, month) {
  const firstDay = new Date(year, month - 1, 1)
  const lastDay = new Date(year, month, 0)

  // 获取第一天是星期几（0-6）
  const firstDayWeek = firstDay.getDay() || 7

  // 填充上月剩余日期
  const prevMonthDays = []
  for (let i = firstDayWeek - 1; i > 0; i--) {
    const day = new Date(year, month - 1, -i + 1)
    prevMonthDays.push(day)
  }

  // 当月日期
  const currentMonthDays = []
  for (let i = 1; i <= lastDay.getDate(); i++) {
    const day = new Date(year, month - 1, i)
    currentMonthDays.push(day)
  }

  // 下月日期（补齐到42天）
  const remainingDays = 42 - prevMonthDays.length - currentMonthDays.length
  const nextMonthDays = []
  for (let i = 1; i <= remainingDays; i++) {
    const day = new Date(year, month, i)
    nextMonthDays.push(day)
  }

  return [...prevMonthDays, ...currentMonthDays, ...nextMonthDays]
}
```

**预计时间**: 2小时

---

#### 页面3：日志详情页（LogDetail.vue）⏳

**参考文件**: 小程序 `pages/log-detail/`

**功能要求**:
- 新增日志（自动使用今天日期）
- 编辑已有日志
- 删除日志（带确认弹窗）
- 自动生成摘要（取前50个字）
- 日期选择器支持
- 只读模式（查看他人日志时）

**路由参数**:
- `:id?` - 可选的日志ID，有ID则编辑，无ID则新增

**核心逻辑**:
```javascript
const route = useRoute()
const logId = route.params.id

if (logId) {
  // 编辑模式：获取日志详情
  const log = await getLogDetail(logId)
  formData.value = log
} else {
  // 新增模式：使用今天日期
  formData.value.logDate = formatDate(new Date())
}
```

**预计时间**: 1.5小时

---

#### 页面4：用户列表页（UserList.vue）⏳

**参考文件**: 小程序 `pages/user-list/`

**功能要求**:
- 获取系统用户列表
- 按部门分组展示
- 部门展开/收起功能
- 选择用户查看其日志

**数据结构**:
```javascript
{
  allUsers: [],        // 所有用户
  deptGroups: [],      // 按部门分组
  expandedDepts: {},   // 展开的部门
  loaded: false        // 是否已加载
}
```

**核心逻辑**:
```javascript
// 按部门分组
function groupByDept(users) {
  const groups = {}
  users.forEach(user => {
    const dept = user.dept?.deptName || '未分组'
    if (!groups[dept]) {
      groups[dept] = []
    }
    groups[dept].push(user)
  })
  return Object.entries(groups).map(([deptName, userList]) => ({
    deptName,
    userList
  }))
}
```

**预计时间**: 1小时

---

#### 页面5：个人中心页（Profile.vue）⏳

**参考文件**: 小程序 `pages/profile/`

**功能要求**:
- 显示用户信息（头像、昵称、部门等）
- 退出登录
- 编辑资料（功能开发中）
- 修改密码（功能开发中）
- 系统设置（功能开发中）

**页面结构**:
```vue
<template>
  <div class="profile-page">
    <!-- 用户信息卡片 -->
    <UserCard :user="userInfo" />

    <!-- 功能列表 -->
    <van-cell-group>
      <van-cell title="编辑资料" is-link @click="editProfile" />
      <van-cell title="修改密码" is-link @click="changePassword" />
      <van-cell title="系统设置" is-link @click="settings" />
    </van-cell-group>

    <!-- 退出登录按钮 -->
    <van-button type="danger" block @click="handleLogout">
      退出登录
    </van-button>
  </div>
</template>
```

**预计时间**: 1小时

---

### 阶段三：静态资源迁移（最后进行）

#### 迁移图片资源

**命令**:
```bash
cp -r ../images/* public/images/
```

**图片列表**:
- delete.svg - 删除图标
- edit.svg - 编辑图标
- edit_1.svg - 编辑图标变体
- password.svg - 密码图标
- setting.svg - 设置图标
- user.svg - 用户图标

**注意**: SVG在H5中可以直接使用，或转换为字体图标

**预计时间**: 10分钟

---

### 阶段四：测试与优化

#### 测试清单

1. **功能测试**
   - [ ] 登录流程正常
   - [ ] 日志列表显示正确
   - [ ] 周切换功能正常
   - [ ] 新增/编辑/删除日志正常
   - [ ] 日历显示正确
   - [ ] 用户列表加载正常
   - [ ] 查看他人日志功能正常
   - [ ] 退出登录正常

2. **兼容性测试**
   - [ ] Chrome移动端模拟
   - [ ] Safari iOS
   - [ ] Android Chrome
   - [ ] 不同屏幕尺寸

3. **性能优化**
   - [ ] 长列表虚拟滚动
   - [ ] 图片懒加载
   - [ ] 代码分割优化

**预计时间**: 2-3小时

---

## 开发命令速查

### 启动开发服务器
```bash
cd /Users/servert/PycharmProjects/dayuniapp/dayuniapp-h5
npm run dev
```
访问: http://localhost:3000

### 构建生产版本
```bash
npm run build
```
生成文件在 `dist/` 目录

### 预览生产构建
```bash
npm run preview
```

---

## 环境配置

### 开发环境（.env.development）
```env
VITE_API_BASE_URL=http://127.0.0.1:9100
```

### 生产环境（.env.production）
```env
# 部署时修改为实际服务器地址
VITE_API_BASE_URL=http://your-server.com:9100
```

---

## API使用示例

### 在组件中调用API
```javascript
import { addLog, updateLog, deleteLog } from '@/api'

// 新增日志
await addLog({
  log_date: '2026-01-21',
  content: '今天完成了...',
  summary: '摘要...',
  remark: '备注...'
})

// 编辑日志
await updateLog({
  id: 1,
  log_date: '2026-01-21',
  content: '更新内容...'
})

// 删除日志
await deleteLog(1)
```

### 在组件中使用Store
```javascript
import { useUserStore, useLogStore } from '@/stores'

const userStore = useUserStore()
const logStore = useLogStore()

// 用户信息
console.log(userStore.userInfo)
console.log(userStore.isAdmin)

// 日志数据
console.log(logStore.weekLogs)
console.log(logStore.workStats)

// 调用action
await logStore.fetchWeekLogs('2026-01-20')
```

---

## 常见问题

### Q1: API请求跨域问题？
**A**: 开发环境已配置Vite代理，生产环境需要后端配置CORS

### Q2: 路径别名@不生效？
**A**: 确保vite.config.js中已配置alias，重启VSCode

### Q3: localStorage在隐私模式下报错？
**A**: 使用try-catch包裹或使用sessionStorage

### Q4: iPhone底部黑屏遮挡内容？
**A**: 已配置safe-area-inset-bottom，确保页面有padding-bottom

---

## 下一步行动

1. **立即执行**: 创建Home.vue（日志主页）
2. **然后**: 创建Calendar.vue（日历页）
3. **然后**: 创建LogDetail.vue（日志详情）
4. **然后**: 创建UserList.vue（用户列表）
5. **最后**: 创建Profile.vue（个人中心）

---

## 时间估算

| 任务 | 预计时间 | 状态 |
|------|---------|------|
| 项目基础搭建 | 2小时 | ✅ 已完成 |
| 登录页面 | 1小时 | ✅ 已完成 |
| TabBar组件 | 0.5小时 | ✅ 已完成 |
| 日志主页 | 1.5小时 | ⏳ 待进行 |
| 日历页面 | 2小时 | ⏳ 待进行 |
| 日志详情 | 1.5小时 | ⏳ 待进行 |
| 用户列表 | 1小时 | ⏳ 待进行 |
| 个人中心 | 1小时 | ⏳ 待进行 |
| 资源迁移 | 0.5小时 | ⏳ 待进行 |
| 测试优化 | 3小时 | ⏳ 待进行 |
| **总计** | **14小时** | **40%完成** |

---

## 文件对照表

| 小程序文件 | H5文件 | 状态 |
|-----------|--------|------|
| `pages/login/` | `src/views/Login.vue` | ✅ 已完成 |
| `pages/index/` | `src/views/Home.vue` | ⏳ 待创建 |
| `pages/calendar/` | `src/views/Calendar.vue` | ⏳ 待创建 |
| `pages/log-detail/` | `src/views/LogDetail.vue` | ⏳ 待创建 |
| `pages/user-list/` | `src/views/UserList.vue` | ⏳ 待创建 |
| `pages/profile/` | `src/views/Profile.vue` | ⏳ 待创建 |
| `custom-tab-bar/` | `src/components/TabBar.vue` | ✅ 已完成 |
| `utils/request.js` | `src/api/request.js` + `src/api/index.js` | ✅ 已完成 |
| `app.js` | `src/stores/user.js` + `src/stores/log.js` | ✅ 已完成 |

---

**准备好继续了吗？我可以帮你创建下一个页面！**
