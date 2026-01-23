/**
 * 日志状态管理
 * 使用 Pinia
 */

import { defineStore } from 'pinia'
import {
  getWeekLogs,
  getMonthLogs,
  getUserWeekLogs,
  getUserMonthLogs
} from '@/api'

export const useLogStore = defineStore('log', {
  state: () => ({
    // 周视图数据
    weekLogs: [],
    weekStart: '',
    weekEnd: '',
    weekOffset: 0,

    // 月历视图数据
    monthLogs: [],
    currentYear: new Date().getFullYear(),
    currentMonth: new Date().getMonth() + 1,

    // 查看他人日志
    viewingUserId: null,
    viewingUserName: '',

    // 加载状态
    loading: false
  }),

  getters: {
    // 本周有日志的日期
    weekLogDates: (state) => {
      return state.weekLogs.map(log => log.log_date)
    },

    // 本月有日志的日期
    monthLogDates: (state) => {
      return state.monthLogs.map(log => log.log_date)
    },

    // 工作日统计
    workStats: (state) => {
      const workDays = state.weekLogs.filter(log => log.content && log.content.trim()).length
      const totalLogs = state.weekLogs.length
      const emptyDays = 7 - totalLogs

      return {
        workDays,
        totalLogs,
        emptyDays
      }
    }
  },

  actions: {
    /**
     * 获取周历数据
     */
    async fetchWeekLogs(startDate) {
      this.loading = true
      try {
        const params = { start: startDate }
        let res

        if (this.viewingUserId) {
          res = await getUserWeekLogs(this.viewingUserId, startDate)
        } else {
          res = await getWeekLogs(startDate)
        }

        this.weekLogs = res.data || []
        this.weekStart = res.weekStart || startDate
        this.weekEnd = res.weekEnd || startDate

        return res
      } catch (error) {
        console.error('获取周历数据失败:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * 获取月历数据
     */
    async fetchMonthLogs(year, month) {
      this.loading = true
      try {
        let res

        if (this.viewingUserId) {
          res = await getUserMonthLogs(this.viewingUserId, year, month)
        } else {
          res = await getMonthLogs(year, month)
        }

        this.monthLogs = res.data || []
        this.currentYear = year
        this.currentMonth = month

        return res
      } catch (error) {
        console.error('获取月历数据失败:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * 切换到上一周
     */
    async previousWeek() {
      this.weekOffset--
      // 计算上一周的开始日期
      const startDate = this.calculateWeekStart(this.weekOffset)
      await this.fetchWeekLogs(startDate)
    },

    /**
     * 切换到下一周
     */
    async nextWeek() {
      this.weekOffset++
      const startDate = this.calculateWeekStart(this.weekOffset)
      await this.fetchWeekLogs(startDate)
    },

    /**
     * 回到本周
     */
    async backToThisWeek() {
      this.weekOffset = 0
      const today = new Date()
      const startDate = this.getMondayOfWeek(today)
      await this.fetchWeekLogs(this.formatDate(startDate))
    },

    /**
     * 设置查看的用户
     */
    setViewingUser(userId, userName) {
      this.viewingUserId = userId
      this.viewingUserName = userName
      // 清空缓存，避免数据混淆
      this.weekLogs = []
      this.monthLogs = []
    },

    /**
     * 清除查看的用户
     */
    clearViewingUser() {
      this.viewingUserId = null
      this.viewingUserName = ''
      this.weekOffset = 0
      // 清空缓存，避免数据混淆
      this.weekLogs = []
      this.monthLogs = []
    },

    /**
     * 计算周开始日期
     */
    calculateWeekStart(offset) {
      const today = new Date()
      const monday = this.getMondayOfWeek(today)
      monday.setDate(monday.getDate() + (offset * 7))
      return this.formatDate(monday)
    },

    /**
     * 获取本周一
     */
    getMondayOfWeek(date) {
      const day = date.getDay()
      const diff = date.getDate() - day + (day === 0 ? -6 : 1)
      return new Date(date.setDate(diff))
    },

    /**
     * 格式化日期为 YYYY-MM-DD
     */
    formatDate(date) {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    }
  }
})
