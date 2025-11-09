"use client"

import type React from "react"
import { useEffect, useState } from "react"
import type { AppType, WindowState } from "./desktop"
import {
  FinderIcon,
  SafariIcon,
  MessagesIcon,
  CalendarIcon,
  PhotosIcon,
  MusicIcon,
  NotesIcon,
  VSCodeIcon,
  TerminalIcon,
  DockerIcon,
  GitIcon,
  SettingsIcon,
  LaunchpadIcon,
  EmployeeHandbookIcon,
  MCCAdminIcon,
  OneScopeIcon,
  MarketingCMSIcon,
  AppSimulatorIcon,
  DesignSystemIcon,
} from "./app-icons"

interface DockProps {
  onAppClick: (app: AppType, title: string) => void
  minimizedWindows: WindowState[]
  onUnminimize: (id: string) => void
  onLaunchpadClick: () => void
  openApps: AppType[]
  onCloseApp: (app: AppType) => void // Added onCloseApp prop
}

const dockApps = [
  { id: "finder" as AppType, icon: FinderIcon, label: "Finder" },
  { id: "employee-handbook" as AppType, icon: EmployeeHandbookIcon, label: "Employee Handbook" },
  { id: "mcc-admin" as AppType, icon: MCCAdminIcon, label: "MCC Admin" },
  { id: "onescope" as AppType, icon: OneScopeIcon, label: "OneScope" },
  { id: "marketing-cms" as AppType, icon: MarketingCMSIcon, label: "Marketing CMS" },
  { id: "app-simulator" as AppType, icon: AppSimulatorIcon, label: "App Simulator" },
  { id: "design-system" as AppType, icon: DesignSystemIcon, label: "Design System" },
  { id: "terminal" as AppType, icon: TerminalIcon, label: "Terminal" },
  { id: "settings" as AppType, icon: SettingsIcon, label: "Settings" },
]

export function Dock({
  onAppClick,
  minimizedWindows,
  onUnminimize,
  onLaunchpadClick,
  openApps,
  onCloseApp,
}: DockProps) {
  const [hoveredApp, setHoveredApp] = useState<string | null>(null)
  const [contextMenu, setContextMenu] = useState<{ app: AppType; x: number; y: number } | null>(null)

  const handleContextMenu = (e: React.MouseEvent, app: AppType) => {
    e.preventDefault()
    e.stopPropagation() // Stop propagation to prevent desktop context menu
    setContextMenu({ app, x: e.clientX, y: e.clientY })
  }

  useEffect(() => {
    const handleClickOutside = () => setContextMenu(null)
    if (contextMenu) {
      document.addEventListener("click", handleClickOutside)
      return () => document.removeEventListener("click", handleClickOutside)
    }
  }, [contextMenu])

  return (
    <>
      <div className="fixed bottom-0 md:bottom-2 left-0 md:left-1/2 md:-translate-x-1/2 z-50 w-full md:w-auto">
        <div className="md:bg-white/30 md:cu-blur md:cu-dock-shadow md:rounded-2xl md:px-2 md:py-2 bg-white/40 backdrop-blur-xl border-t border-white/20 md:border md:border-white/20 overflow-x-auto overflow-y-hidden scrollbar-hide">
          <div className="flex items-end gap-1 px-2 py-2 md:px-0 md:py-0 min-w-max">
            {/* Launchpad icon */}
            <button
              className="relative group transition-transform duration-200 ease-out flex-shrink-0"
              style={{
                transform: hoveredApp === "launchpad" ? "scale(1.2) translateY(-8px)" : "scale(1)",
              }}
              onClick={onLaunchpadClick}
              onMouseEnter={() => setHoveredApp("launchpad")}
              onMouseLeave={() => setHoveredApp(null)}
            >
              <div className="w-12 h-12 md:w-14 md:h-14 rounded-xl shadow-lg overflow-hidden">
                <LaunchpadIcon />
              </div>
              <div className="absolute -top-10 left-1/2 -translate-x-1/2 bg-gray-800/90 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
                Launchpad
              </div>
            </button>

            <div className="w-px h-10 md:h-12 bg-white/30 mx-1 flex-shrink-0" />

            {dockApps.map((app, index) => {
              const isHovered = hoveredApp === app.id
              const isOpen = openApps.includes(app.id)
              const IconComponent = app.icon

              return (
                <button
                  key={app.id}
                  data-app={app.id}
                  className="relative group transition-transform duration-200 ease-out flex-shrink-0"
                  style={{
                    transform: isHovered ? "scale(1.2) translateY(-8px)" : "scale(1)",
                  }}
                  onMouseEnter={() => setHoveredApp(app.id)}
                  onMouseLeave={() => setHoveredApp(null)}
                  onClick={() => onAppClick(app.id, app.label)}
                  onContextMenu={(e) => handleContextMenu(e, app.id)}
                >
                  <div className="w-12 h-12 md:w-14 md:h-14 rounded-xl shadow-lg overflow-hidden">
                    <IconComponent />
                  </div>

                  {/* Tooltip */}
                  <div className="absolute -top-10 left-1/2 -translate-x-1/2 bg-gray-800/90 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
                    {app.label}
                  </div>

                  {/* Running indicator */}
                  {isOpen && (
                    <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 bg-gray-700 rounded-full" />
                  )}
                </button>
              )
            })}

            {/* Divider */}
            {minimizedWindows.length > 0 && <div className="w-px h-10 md:h-12 bg-white/30 mx-1 flex-shrink-0" />}

            {/* Minimized windows */}
            {minimizedWindows.map((window) => (
              <button
                key={window.id}
                className="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-white/50 flex items-center justify-center text-2xl shadow-lg hover:scale-110 transition-transform flex-shrink-0"
                onClick={() => onUnminimize(window.id)}
              >
                📄
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Context menu */}
      {contextMenu && (
        <div
          className="fixed bg-white/95 backdrop-blur-xl border border-black/10 rounded-lg shadow-2xl py-1 z-[60] min-w-[180px]"
          style={{ left: contextMenu.x, top: contextMenu.y - 120 }}
          onClick={(e) => e.stopPropagation()}
        >
          <button
            className="w-full px-4 py-1.5 text-left text-sm text-gray-700 hover:bg-blue-500 hover:text-white transition-colors"
            onClick={() => {
              console.log("Options for", contextMenu.app)
              setContextMenu(null)
            }}
          >
            Options
          </button>
          <button
            className="w-full px-4 py-1.5 text-left text-sm text-gray-700 hover:bg-blue-500 hover:text-white transition-colors"
            onClick={() => {
              console.log("Show in Finder")
              setContextMenu(null)
            }}
          >
            Show in Finder
          </button>
          <div className="h-px bg-black/10 my-1" />
          <button
            className="w-full px-4 py-1.5 text-left text-sm text-red-600 hover:bg-red-500 hover:text-white transition-colors font-medium"
            onClick={() => {
              onCloseApp(contextMenu.app)
              setContextMenu(null)
            }}
          >
            Quit
          </button>
        </div>
      )}
    </>
  )
}
