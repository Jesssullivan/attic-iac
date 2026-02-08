export interface Notification {
  id: string;
  type: "info" | "success" | "warning" | "error";
  message: string;
  timeout?: number;
}

let notifications = $state<Notification[]>([]);

let counter = 0;

export const notificationsStore = {
  get list() {
    return notifications;
  },
  add(type: Notification["type"], message: string, timeout = 5000) {
    const id = `notif-${++counter}`;
    const notification: Notification = { id, type, message, timeout };
    notifications = [...notifications, notification];

    if (timeout > 0) {
      setTimeout(() => this.remove(id), timeout);
    }

    return id;
  },
  remove(id: string) {
    notifications = notifications.filter((n) => n.id !== id);
  },
  clear() {
    notifications = [];
  },
  info(message: string, timeout?: number) {
    return this.add("info", message, timeout);
  },
  success(message: string, timeout?: number) {
    return this.add("success", message, timeout);
  },
  warning(message: string, timeout?: number) {
    return this.add("warning", message, timeout);
  },
  error(message: string, timeout?: number) {
    return this.add("error", message, timeout ?? 0);
  },
};
