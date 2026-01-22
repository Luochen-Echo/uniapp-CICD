/**
 * 用户状态管理
 * 使用 Pinia
 */

import { defineStore } from 'pinia'
import { login as loginApi, getUserInfo, logout as logoutApi } from '@/api'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    userInfo: null,
    permissions: null // 用户权限列表
  }),

  getters: {
    // 是否已登录
    isLoggedIn: (state) => !!state.token,

    // 是否有权限查看他人日志（基于 permissions）
    canViewOthers: (state) => {
      if (!state.permissions || !Array.isArray(state.permissions)) {
        return false
      }

      // 1. 检查是否有超级管理员权限（通配符）
      if (state.permissions.includes('*:*:*')) {
        return true
      }

      // 2. 检查是否有 work-log:view 权限
      return state.permissions.includes('work-log:view')
    },

    // 是否是管理员或团队领导（保留旧逻辑以兼容）
    isAdmin: (state) => {
      if (!state.userInfo) return false

      // 1. 优先检查 admin 字段（布尔值）
      if (state.userInfo.admin === true) {
        return true
      }

      // 2. 检查 role 字段（可能是数组）
      const roles = state.userInfo.role || state.userInfo.roles || state.userInfo.roleArray

      if (!roles) {
        return false
      }

      // 如果是数组，检查数组中的角色
      if (Array.isArray(roles)) {
        return roles.some(role =>
          role.roleKey === 'admin' || role.roleKey === 'team_leader' || role.roleSort === 1
        )
      }

      // 如果是单个角色对象
      if (roles.roleKey === 'admin' || roles.roleKey === 'team_leader' || roles.roleSort === 1) {
        return true
      }

      return false
    },

    // 用户昵称
    nickName: (state) => state.userInfo?.nickName || '',

    // 用户头像
    avatar: (state) => state.userInfo?.avatar || ''
  },

  actions: {
    /**
     * 设置token
     */
    setToken(token) {
      this.token = token
      localStorage.setItem('token', token)
    },

    /**
     * 设置用户信息
     */
    setUserInfo(userInfo, permissions = null) {
      this.userInfo = userInfo
      if (permissions) {
        this.permissions = permissions
      }
    },

    /**
     * 登录
     */
    async login(username, password, code = '', uuid = '') {
      try {
        const res = await loginApi(username, password, code, uuid)
        this.setToken(res.token)

        // 登录成功后获取用户信息
        await this.fetchUserInfo()

        return res
      } catch (error) {
        throw error
      }
    },

    /**
     * 获取用户信息
     */
    async fetchUserInfo() {
      try {
        const res = await getUserInfo()
        this.setUserInfo(res.user, res.permissions || [])
        return res
      } catch (error) {
        throw error
      }
    },

    /**
     * 退出登录
     */
    async logout() {
      try {
        await logoutApi()
      } catch (error) {
        console.error('退出登录失败:', error)
      } finally {
        this.token = ''
        this.userInfo = null
        this.permissions = null
        localStorage.removeItem('token')
      }
    }
  }
})
