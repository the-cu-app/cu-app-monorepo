"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { MenuBar } from "./menu-bar"
import { Dock } from "./dock"
import { Window } from "./window"
import { DesktopIcon } from "./desktop-icon"
import { Spotlight } from "./spotlight"
import { ContextMenu } from "./context-menu"
import { NotificationCenter } from "./notification-center"
import { Launchpad } from "./launchpad"
import { AboutThisMac } from "./about-this-mac"
import { ControlCenter } from "./control-center"
import { Finder } from "./apps/finder"
import { Safari } from "./apps/safari"
import { Messages } from "./apps/messages"
import { Settings } from "./apps/settings"
import { Calendar } from "./apps/calendar"
import { Photos } from "./apps/photos"
import { Music } from "./apps/music"
import { Notes } from "./apps/notes"
import { VSCode } from "./apps/vscode"
import { Terminal } from "./apps/terminal"
import { Docker } from "./apps/docker"
import { GitBash } from "./apps/git-bash"
import { Dashboard } from "./apps/dashboard"
import { EmployeeHandbook } from "./apps/employee-handbook"
import { MCCAdmin } from "./apps/mcc-admin"
import { OneScope } from "./apps/onescope"
import { MarketingCMS } from "./apps/marketing-cms"
import { AppSimulator } from "./apps/app-simulator"
import { DesignSystem } from "./apps/design-system"
import { DownloadsIcon } from "./app-icons"
import { ClockWidget } from "./widgets/clock-widget"
import { CalendarWidget } from "./widgets/calendar-widget"
import { AnimatedWallpaper } from "./animated-wallpaper"
import { AIAssistant } from "./ai-assistant"
import type { User } from "./login-screen"
import { hasPermission, type Feature } from "@/lib/permissions"
import { Sparkles } from "lucide-react"

export type AppType =
  | "finder"
  | "safari"
  | "messages"
  | "settings"
  | "calendar"
  | "photos"
  | "music"
  | "notes"
  | "vscode"
  | "terminal"
  | "docker"
  | "git"
  | "dashboard"
  | "employee-handbook"
  | "mcc-admin"
  | "onescope"
  | "marketing-cms"
  | "app-simulator"
  | "design-system"

export interface WindowState {
  id: string
  app: AppType
  title: string
  isMinimized: boolean
  isMaximized: boolean
  position: { x: number; y: number }
  size: { width: number; height: number }
  zIndex: number
}

interface ContextMenuState {
  x: number
  y: number
  items: Array<{ label: string; action: () => void; divider?: boolean }>
}

interface CU OSDesktopProps {
  user: User
  onLogout: () => void
}

export function CU OSDesktop({ user, onLogout }: CU OSDesktopProps) {
  const [windows, setWindows] = useState<WindowState[]>([])
  const [highestZIndex, setHighestZIndex] = useState(10)
  const [currentTime, setCurrentTime] = useState(new Date())
  const [spotlightOpen, setSpotlightOpen] = useState(false)
  const [contextMenu, setContextMenu] = useState<ContextMenuState | null>(null)
  const [notificationCenterOpen, setNotificationCenterOpen] = useState(false)
  const [launchpadOpen, setLaunchpadOpen] = useState(false)
  const [activeApp, setActiveApp] = useState<string>("Finder")
  const [aboutThisMacOpen, setAboutThisMacOpen] = useState(false)
  const [controlCenterOpen, setControlCenterOpen] = useState(false)
  const [aiAssistantOpen, setAiAssistantOpen] = useState(false)

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000)
    return () => clearInterval(timer)
  }, [])

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault()
        setAiAssistantOpen(!aiAssistantOpen)
      }
      if ((e.metaKey || e.ctrlKey) && e.key === " ") {
        e.preventDefault()
        setSpotlightOpen(true)
      }
      if (e.key === "Escape") {
        setSpotlightOpen(false)
        setLaunchpadOpen(false)
        setContextMenu(null)
        setAiAssistantOpen(false)
      }
      if (e.key === "F4" || (e.ctrlKey && e.key === "ArrowUp")) {
        e.preventDefault()
        setLaunchpadOpen(!launchpadOpen)
      }
    }

    const handleClick = () => {
      setContextMenu(null)
    }

    window.addEventListener("keydown", handleKeyDown)
    window.addEventListener("click", handleClick)
    return () => {
      window.removeEventListener("keydown", handleKeyDown)
      window.removeEventListener("click", handleClick)
    }
  }, [launchpadOpen, aiAssistantOpen])

  const canAccessApp = (feature: Feature): boolean => {
    return hasPermission(user.role, feature)
  }

  const openApp = (app: AppType, title: string) => {
    const featureMap: Record<AppType, Feature> = {
      finder: "finder",
      safari: "dashboard",
      messages: "messaging",
      settings: "settings",
      calendar: "calendar",
      photos: "dashboard",
      music: "dashboard",
      notes: "notes",
      vscode: "terminal",
      terminal: "terminal",
      docker: "terminal",
      git: "terminal",
      dashboard: "dashboard",
    }

    const feature = featureMap[app]
    if (feature && !canAccessApp(feature)) {
      alert(`Access Denied: Your role (${user.role}) does not have permission to access ${title}`)
      return
    }

    setLaunchpadOpen(false)
    setActiveApp(title)
    const existingWindow = windows.find((w) => w.app === app && !w.isMinimized)

    if (existingWindow) {
      focusWindow(existingWindow.id)
      const dockIcon = document.querySelector(`[data-app="${app}"]`)
      if (dockIcon) {
        dockIcon.classList.add("animate-bounce")
        setTimeout(() => dockIcon.classList.remove("animate-bounce"), 500)
      }
      return
    }

    const minimizedWindow = windows.find((w) => w.app === app && w.isMinimized)
    if (minimizedWindow) {
      unminimizeWindow(minimizedWindow.id)
      return
    }

    const newWindow: WindowState = {
      id: `${app}-${Date.now()}`,
      app,
      title,
      isMinimized: false,
      isMaximized: false,
      position: { x: 100 + windows.length * 30, y: 80 + windows.length * 30 },
      size: { width: 900, height: 600 },
      zIndex: highestZIndex + 1,
    }

    setWindows([...windows, newWindow])
    setHighestZIndex(highestZIndex + 1)
  }

  const closeWindow = (id: string) => {
    setWindows(windows.filter((w) => w.id !== id))
  }

  const minimizeWindow = (id: string) => {
    setWindows(windows.map((w) => (w.id === id ? { ...w, isMinimized: true } : w)))
  }

  const unminimizeWindow = (id: string) => {
    setWindows(windows.map((w) => (w.id === id ? { ...w, isMinimized: false, zIndex: highestZIndex + 1 } : w)))
    setHighestZIndex(highestZIndex + 1)
  }

  const maximizeWindow = (id: string) => {
    setWindows(
      windows.map((w) =>
        w.id === id
          ? {
              ...w,
              isMaximized: !w.isMaximized,
              position: w.isMaximized ? w.position : { x: 0, y: 28 },
              size: w.isMaximized ? w.size : { width: window.innerWidth, height: window.innerHeight - 28 - 80 },
            }
          : w,
      ),
    )
  }

  const focusWindow = (id: string) => {
    const newZIndex = highestZIndex + 1
    setWindows(windows.map((w) => (w.id === id ? { ...w, zIndex: newZIndex } : w)))
    setHighestZIndex(newZIndex)
    const window = windows.find((w) => w.id === id)
    if (window) {
      setActiveApp(window.title)
    }
  }

  const updateWindowPosition = (id: string, position: { x: number; y: number }) => {
    setWindows(windows.map((w) => (w.id === id ? { ...w, position } : w)))
  }

  const updateWindowSize = (id: string, size: { width: number; height: number }) => {
    setWindows(windows.map((w) => (w.id === id ? { ...w, size } : w)))
  }

  const handleDesktopContextMenu = (e: React.MouseEvent) => {
    e.preventDefault()
    setContextMenu({
      x: e.clientX,
      y: e.clientY,
      items: [
        { label: "New Folder", action: () => console.log("New folder") },
        { label: "Get Info", action: () => console.log("Get info") },
        { divider: true, label: "", action: () => {} },
        { label: "Change Desktop Background...", action: () => openApp("settings", "Settings") },
        { divider: true, label: "", action: () => {} },
        { label: "Show View Options", action: () => console.log("View options") },
      ],
    })
  }

  const renderAppContent = (app: AppType, title: string) => {
    switch (app) {
      case "dashboard":
        return <Dashboard user={user} />
      case "finder":
        return <Finder initialFolder={title} />
      case "safari":
        return <Safari />
      case "messages":
        return <Messages />
      case "settings":
        return <Settings />
      case "calendar":
        return <Calendar />
      case "photos":
        return <Photos />
      case "music":
        return <Music />
      case "notes":
        return <Notes />
      case "vscode":
        return <VSCode />
      case "terminal":
        return <Terminal />
      case "docker":
        return <Docker />
      case "git":
        return <GitBash />
      case "employee-handbook":
        return <EmployeeHandbook />
      case "mcc-admin":
        return <MCCAdmin />
      case "onescope":
        return <OneScope />
      case "marketing-cms":
        return <MarketingCMS />
      case "app-simulator":
        return <AppSimulator />
      case "design-system":
        return <DesignSystem />
      default:
        return <div className="p-8">App content</div>
    }
  }

  const closeAppByType = (app: AppType) => {
    setWindows(windows.filter((w) => w.app !== app))
  }

  useEffect(() => {
    openApp("dashboard", "Dashboard")
  }, [])

  return (
    <div className="h-screen w-screen overflow-hidden relative bg-gradient-to-br from-blue-400 via-purple-300 to-pink-300">
      <div className="absolute inset-0 bg-gradient-to-br from-[#0a1628] via-[#1e3a5f] to-[#2d5a7b]" />
      <AnimatedWallpaper />

      <div className="absolute inset-0" onContextMenu={handleDesktopContextMenu}>
        <div className="absolute top-20 md:top-32 right-4 md:right-8 flex flex-col gap-4 md:gap-6">
          <DesktopIcon icon={DownloadsIcon} label="Downloads" onDoubleClick={() => openApp("finder", "Downloads")} />
        </div>

        <div className="absolute bottom-24 md:bottom-32 left-4 md:left-8 flex flex-col gap-4">
          <ClockWidget />
          <CalendarWidget />
        </div>
      </div>

      <MenuBar
        currentTime={currentTime}
        activeApp={activeApp}
        onSpotlightClick={() => setSpotlightOpen(true)}
        onNotificationClick={() => setNotificationCenterOpen(!notificationCenterOpen)}
        onAboutThisMac={() => setAboutThisMacOpen(true)}
        onControlCenterClick={() => setControlCenterOpen(!controlCenterOpen)}
        user={user}
        onLogout={onLogout}
      />

      {windows.map(
        (window) =>
          !window.isMinimized && (
            <Window
              key={window.id}
              id={window.id}
              title={window.title}
              position={window.position}
              size={window.size}
              zIndex={window.zIndex}
              isMaximized={window.isMaximized}
              onClose={() => closeWindow(window.id)}
              onMinimize={() => minimizeWindow(window.id)}
              onMaximize={() => maximizeWindow(window.id)}
              onFocus={() => focusWindow(window.id)}
              onPositionChange={(pos) => updateWindowPosition(window.id, pos)}
              onSizeChange={(size) => updateWindowSize(window.id, size)}
            >
              {renderAppContent(window.app, window.title)}
            </Window>
          ),
      )}

      <Dock
        onAppClick={openApp}
        minimizedWindows={windows.filter((w) => w.isMinimized)}
        onUnminimize={unminimizeWindow}
        onLaunchpadClick={() => setLaunchpadOpen(!launchpadOpen)}
        openApps={windows.map((w) => w.app)}
        onCloseApp={closeAppByType}
        user={user}
      />

      {spotlightOpen && <Spotlight onClose={() => setSpotlightOpen(false)} onOpenApp={openApp} />}

      {contextMenu && <ContextMenu x={contextMenu.x} y={contextMenu.y} items={contextMenu.items} />}

      {notificationCenterOpen && <NotificationCenter onClose={() => setNotificationCenterOpen(false)} />}

      {launchpadOpen && <Launchpad onClose={() => setLaunchpadOpen(false)} onOpenApp={openApp} />}

      {aboutThisMacOpen && <AboutThisMac onClose={() => setAboutThisMacOpen(false)} />}

      {controlCenterOpen && <ControlCenter onClose={() => setControlCenterOpen(false)} />}

      <button
        onClick={() => setAiAssistantOpen(true)}
        className="fixed bottom-24 right-4 z-[9999] bg-black text-white p-4 rounded-full shadow-2xl hover:bg-gray-900 transition-all hover:scale-110"
        title="AI Assistant (Cmd+K)"
      >
        <Sparkles className="w-6 h-6" />
      </button>

      {aiAssistantOpen && <AIAssistant user={user} onClose={() => setAiAssistantOpen(false)} />}
    </div>
  )
}
