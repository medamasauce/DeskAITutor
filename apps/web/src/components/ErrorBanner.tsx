export function ErrorBanner({ message, onDismiss }: { message: string; onDismiss: () => void }) {
  return (
    <div className="error-banner">
      <span>{message}</span>
      <button onClick={onDismiss}>閉じる</button>
    </div>
  )
}
