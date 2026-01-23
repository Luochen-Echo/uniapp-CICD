<template>
  <div class="calendar-page">
    <!-- 导航栏占位 -->
    <div class="navbar-placeholder"></div>

    <!-- 月份选择器 -->
    <div class="month-selector">
      <div class="nav-arrow" @click="changeMonth(-1)">◀</div>
      <div class="month-text" @click="showDatePicker = true">
        <span v-if="logStore.viewingUserId">{{ logStore.viewingUserName }}的日志</span>
        <span v-else>我的日志</span>
        （{{ currentYear }}年{{ currentMonth }}月）
      </div>
      <div class="nav-actions">
        <!-- 返回自己的日志按钮（查看他人时显示） -->
        <div class="action-btn back-btn" v-if="logStore.viewingUserId" @click="backToMyLogs">
          返回我的
        </div>
        <!-- 切换用户按钮（有权限且查看自己时显示） -->
        <div class="action-btn switch-btn" v-if="canViewOthers && !logStore.viewingUserId" @click="goToUserList">
          切换用户
        </div>
        <div class="nav-arrow" @click="changeMonth(1)">▶</div>
      </div>
    </div>

    <!-- 星期标题 -->
    <div class="weekday-header">
      <div class="weekday-item" v-for="(day, index) in weekdays" :key="index">{{ day }}</div>
    </div>

    <!-- 日历网格 -->
    <div class="calendar-grid">
      <div
        class="day-item"
        v-for="day in calendarDays"
        :key="day.dateStr"
        @click="selectDate(day)"
      >
        <!-- 今天标记 -->
        <div class="today-badge" v-if="day.isToday">今天</div>

        <!-- 日期数字 -->
        <div
          class="day-number"
          :class="{
            'is-today': day.isToday,
            'other-month': day.isOtherMonth,
            'selected': selectedDate === day.dateStr,
            'has-log': day.hasLog
          }"
        >
          {{ day.day }}
        </div>

        <!-- 日志标记点 -->
        <div class="log-dot" v-if="day.hasLog && !day.isOtherMonth"></div>
      </div>
    </div>

    <!-- 选中日期的日志预览 -->
    <div class="log-preview" v-if="selectedDate" @click="goToDetail">
      <div class="preview-header">
        <span class="preview-title">{{ selectedDateText }}</span>
        <span class="preview-action" v-if="selectedLog">查看详情</span>
      </div>
      <div class="preview-content" v-if="selectedLog">
        <div class="work-label">今日工作</div>
        <div class="work-content">
          <span>{{ selectedLog.summary || '暂无内容' }}</span>
        </div>
      </div>
      <div class="empty-log" v-else>
        <span>点击添加日志</span>
      </div>
    </div>

    <!-- 底部安全区 -->
    <div class="safe-area"></div>

    <!-- 底部悬浮添加按钮 -->
    <div class="floating-add-btn" @click="addLog" v-if="!logStore.viewingUserId">+</div>

    <!-- 日期选择弹窗 -->
    <van-popup v-model:show="showDatePicker" position="bottom">
      <van-date-picker
        v-model="pickerDate"
        title="选择日期"
        :min-date="minDate"
        :max-date="maxDate"
        @confirm="onDateConfirm"
        @cancel="showDatePicker = false"
      />
    </van-popup>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onActivated } from 'vue'
import { useRouter } from 'vue-router'
import { showToast } from 'vant'
import { useLogStore } from '@/stores/log'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const logStore = useLogStore()
const userStore = useUserStore()

// 当前年月
const currentYear = ref(new Date().getFullYear())
const currentMonth = ref(new Date().getMonth() + 1)

// 日期选择器
const showDatePicker = ref(false)
const pickerDate = ref([new Date().getFullYear(), new Date().getMonth() + 1, new Date().getDate()])
const minDate = ref(new Date(2020, 0, 1))
const maxDate = ref(new Date(2030, 11, 31))

// 星期标题
const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 日历数据
const calendarDays = ref([])
const selectedDate = ref('')
const selectedDateText = ref('')
const selectedLog = ref(null)
const todayStr = ref('')

// 权限
const canViewOthers = computed(() => {
  console.log('Calendar - 计算权限检查')
  console.log('Calendar - userStore.permissions:', userStore.permissions)

  // 基于权限标识判断，而非角色
  const canView = userStore.canViewOthers
  console.log('Calendar - 是否有查看他人日志权限:', canView)

  return canView
})

// 初始化
onMounted(() => {
  const today = new Date()
  todayStr.value = formatDate(today)
  loadMonthLogs()
})

onActivated(() => {
  loadMonthLogs()
})

// 切换月份
function changeMonth(offset) {
  let year = currentYear.value
  let month = currentMonth.value + offset

  if (month > 12) {
    month = 1
    year++
  } else if (month < 1) {
    month = 12
    year--
  }

  currentYear.value = year
  currentMonth.value = month
  selectedDate.value = ''
  selectedDateText.value = ''
  selectedLog.value = null

  loadMonthLogs()
}

// 加载月度日志
async function loadMonthLogs() {
  try {
    const res = await logStore.fetchMonthLogs(currentYear.value, currentMonth.value)
    const monthLogs = res.data?.logs || {}
    generateCalendar(monthLogs)
  } catch (error) {
    console.error('加载月度日志失败:', error)
    generateCalendar({})
  }
}

// 生成日历数据
function generateCalendar(monthLogs) {
  const firstDay = new Date(currentYear.value, currentMonth.value - 1, 1)
  const lastDay = new Date(currentYear.value, currentMonth.value, 0)
  const firstWeekday = firstDay.getDay()
  const prevMonthLastDay = new Date(currentYear.value, currentMonth.value - 1, 0).getDate()

  const days = []

  // 填充上个月的日期
  for (let i = firstWeekday - 1; i >= 0; i--) {
    const day = prevMonthLastDay - i
    const date = new Date(currentYear.value, currentMonth.value - 2, day)
    const dateStr = formatDate(date)

    days.push({
      day,
      dateStr,
      isOtherMonth: true,
      isToday: dateStr === todayStr.value,
      hasLog: false,
      log: null
    })
  }

  // 填充当月的日期
  const daysInMonth = lastDay.getDate()
  for (let i = 1; i <= daysInMonth; i++) {
    const date = new Date(currentYear.value, currentMonth.value - 1, i)
    const dateStr = formatDate(date)
    const isToday = dateStr === todayStr.value
    const log = monthLogs[dateStr]
    const hasLog = log && log.id

    days.push({
      day: i,
      dateStr,
      isOtherMonth: false,
      isToday,
      hasLog,
      log: hasLog ? log : null
    })
  }

  // 填充下个月的日期（补齐到42天）
  const remainingDays = 42 - days.length
  for (let i = 1; i <= remainingDays; i++) {
    const date = new Date(currentYear.value, currentMonth.value, i)
    const dateStr = formatDate(date)

    days.push({
      day: i,
      dateStr,
      isOtherMonth: true,
      isToday: dateStr === todayStr.value,
      hasLog: false,
      log: null
    })
  }

  calendarDays.value = days
}

// 格式化日期
function formatDate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// 选择日期（显示预览）
function selectDate(day) {
  if (!day.dateStr) return

  selectedDate.value = day.dateStr

  const date = new Date(day.dateStr)
  selectedDateText.value = `${date.getMonth() + 1}月${date.getDate()}日`
  selectedLog.value = (day.log && day.log.id) ? day.log : null
}

// 跳转到日志详情（编辑页面）
function goToDetail() {
  if (selectedDate.value) {
    router.push(`/log?date=${selectedDate.value}`)
  }
}

// 添加日志
function addLog() {
  if (logStore.viewingUserId) {
    showToast('无法为他人添加日志')
    return
  }

  const today = formatDate(new Date())
  router.push(`/log?date=${today}`)
}

// 日期选择确认
function onDateConfirm() {
  const [year, month, day] = pickerDate.value

  // 提取选中日期的年月
  currentYear.value = year
  currentMonth.value = month

  showDatePicker.value = false
  loadMonthLogs()
}

// 跳转到用户列表
function goToUserList() {
  router.push('/users')
}

// 返回我的日志
function backToMyLogs() {
  logStore.clearViewingUser()
  const today = new Date()
  currentYear.value = today.getFullYear()
  currentMonth.value = today.getMonth() + 1
  selectedDate.value = ''
  selectedDateText.value = ''
  selectedLog.value = null
  loadMonthLogs()
}
</script>

<style lang="scss" scoped>
.calendar-page {
  min-height: 100vh;
  background: #F5F6F7;
  padding-bottom: 50px;
}

/* 导航栏占位 */
.navbar-placeholder {
  height: 56px;
  background: #F5F6F7;
}

/* 月份选择器 */
.month-selector {
  background: #FFFFFF;
  padding: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #E4E7ED;
  position: sticky;
  top: 0;
  z-index: 10;
}

.nav-arrow {
  width: 36px;
  height: 36px;
  border: 1px solid #DEE0E3;
  border-radius: 8px;
  background: #FFFFFF;
  color: #646A73;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  flex-shrink: 0;
  cursor: pointer;

  &:active {
    background: #EBECF0;
    border-color: #3370FF;
  }
}

.month-text {
  flex: 1;
  text-align: center;
  font-size: 16px;
  font-weight: 600;
  color: #1F2329;
  cursor: pointer;
  user-select: none;

  &:active {
    opacity: 0.7;
  }
}

.nav-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.action-btn {
  padding: 0 12px;
  height: 32px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
  white-space: nowrap;
  cursor: pointer;

  &.back-btn {
    border: 1px solid #3370FF;
    background: #FFFFFF;
    color: #3370FF;

    &:active {
      background: #E8F3FF;
    }
  }

  &.switch-btn {
    border: 1px solid #DEE0E3;
    background: #FFFFFF;
    color: #646A73;

    &:active {
      background: #F5F6F7;
    }
  }
}

/* 星期标题 */
.weekday-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  padding: 12px 16px;
  background: #FFFFFF;
}

.weekday-item {
  text-align: center;
  font-size: 13px;
  color: #8F959E;
  font-weight: 500;
}

/* 日历网格 */
.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  padding: 0 16px;
  margin-top: 8px;
}

.day-item {
  aspect-ratio: 1;
  background: #FFFFFF;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  cursor: pointer;
  transition: all 0.2s;

  &:active {
    background: #F5F6F7;
  }
}

.today-badge {
  position: absolute;
  top: 2px;
  font-size: 8px;
  color: #3370FF;
  font-weight: 500;
}

.day-number {
  font-size: 16px;
  font-weight: 500;
  color: #1F2329;
  margin-top: 8px;

  &.is-today {
    color: #3370FF;
    font-weight: 700;
  }

  &.other-month {
    color: #C8C9CC;
  }

  &.selected {
    background: #3370FF;
    color: #FFFFFF;
    border-radius: 50%;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  &.has-log {
    font-weight: 600;
  }
}

.log-dot {
  width: 4px;
  height: 4px;
  background: #3370FF;
  border-radius: 50%;
  position: absolute;
  bottom: 4px;
}

/* 日志预览 */
.log-preview {
  background: #FFFFFF;
  margin: 16px;
  padding: 16px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  cursor: pointer;

  &:active {
    transform: scale(0.98);
  }
}

.preview-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid #E4E7ED;
}

.preview-title {
  font-size: 16px;
  font-weight: 600;
  color: #1F2329;
}

.preview-action {
  font-size: 13px;
  color: #3370FF;
}

.preview-content {
  margin-bottom: 8px;
}

.work-label {
  font-size: 13px;
  font-weight: 600;
  color: #646A73;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  gap: 6px;

  &::before {
    content: '';
    width: 6px;
    height: 6px;
    background: #3370FF;
    border-radius: 50%;
  }
}

.work-content {
  font-size: 14px;
  line-height: 1.8;
  color: #1F2329;
  padding: 12px;
  background: #F5F6F7;
  border-radius: 8px;
  white-space: pre-wrap;
}

.empty-log {
  text-align: center;
  padding: 20px;
  color: #8F959E;
  font-size: 14px;
}

/* 底部安全区 */
.safe-area {
  height: 34px;
}

/* 底部悬浮添加按钮 */
.floating-add-btn {
  position: fixed;
  bottom: calc(50px + env(safe-area-inset-bottom) + 16px);
  right: 16px;
  width: 64px;
  height: 48px;
  background: #3370FF;
  border-radius: 24px;
  color: white;
  font-size: 28px;
  font-weight: 300;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 16px rgba(51, 112, 255, 0.4);
  z-index: 100;
  line-height: 1;
  cursor: pointer;

  &:active {
    transform: scale(0.95);
  }
}
</style>
