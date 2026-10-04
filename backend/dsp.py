import numpy as np
from scipy.signal import butter, filtfilt, welch

class FacialAsymmetryEngine:
    """
    MediaPipe Face Mesh (468 랜드마크) 기준:
    - 코 중심축(Nose Bridge/Tip): 1, 4, 168
    - 좌/우 외안각(Eye Outer Canthus): 33 (우측/화면 좌), 263 (좌측/화면 우)
    - 좌/우 내안각(Eye Inner Canthus): 133, 362
    - 좌/우 콧망울(Alar Base): 102, 331
    - 좌/우 구각(Mouth Corners): 61, 291
    """
    @staticmethod
    def calculate_asymmetry(landmarks_3d: list):
        # landmarks_3d: [[x, y, z], ...] normalized coordinates
        lm = np.array(landmarks_3d)
        
        # 1. 중심축 기준 정규화 (Nose Tip: index 1)
        nose_tip = lm[1]
        
        # 2. 눈꼬리 수직 단차 (Vertical Tilt)
        r_eye = lm[33]
        l_eye = lm[263]
        eye_y_delta = abs(r_eye[1] - l_eye[1]) * 100.0  # Normalized %
        eye_z_delta = abs(r_eye[2] - l_eye[2]) * 100.0  # Z-Depth mm 근사치

        # 3. 입꼬리 비대칭률 (Mouth Corner Asymmetry - 안면마비 핵심 지표)
        r_mouth = lm[61]
        l_mouth = lm[291]
        mouth_y_delta = abs(r_mouth[1] - l_mouth[1]) * 100.0
        mouth_z_delta = abs(r_mouth[2] - l_mouth[2]) * 100.0

        # 4. 코-양볼 3D 뎁스 단차 (Nose Depth Peak Delta)
        cheek_l = lm[205]
        cheek_r = lm[425]
        cheek_avg_z = (cheek_l[2] + cheek_r[2]) / 2.0
        nose_depth_diff_mm = round(abs(nose_tip[2] - cheek_avg_z) * 150.0, 2) # mm 스케일링

        # 비대칭 종합 점수 (0 ~ 100, 15 이상 시 비정상 의심)
        asymmetry_score = round((eye_y_delta * 1.5 + mouth_y_delta * 2.0 + abs(eye_z_delta - mouth_z_delta)), 1)
        is_asymmetry_alert = asymmetry_score > 15.0

        return {
            "depth_diff_mm": nose_depth_diff_mm,
            "eye_tilt_delta": round(eye_y_delta, 2),
            "mouth_corner_delta": round(mouth_y_delta, 2),
            "asymmetry_score": asymmetry_score,
            "is_asymmetry_alert": is_asymmetry_alert
        }

class RPPGProcessor:
    def __init__(self, fps: float = 30.0, window_sec: float = 8.0):
        self.fps = fps
        self.window_size = int(fps * window_sec)
        self.lowcut = 0.75   # 45 BPM
        self.highcut = 3.50  # 210 BPM

    def _butter_bandpass(self, data: np.ndarray) -> np.ndarray:
        nyq = 0.5 * self.fps
        low = self.lowcut / nyq
        high = self.highcut / nyq
        b, a = butter(5, [low, high], btype='band')
        return filtfilt(b, a, data)

    def compute_vitals(self, rgb_buffer: np.ndarray):
        if len(rgb_buffer) < int(self.fps * 3.0):
            return None, None, None

        r = rgb_buffer[:, 0]
        g = rgb_buffer[:, 1]
        b = rgb_buffer[:, 2]

        # CHROM 기법
        r_n = r / (np.mean(r) + 1e-6)
        g_n = g / (np.mean(g) + 1e-6)
        b_n = b / (np.mean(b) + 1e-6)

        xs = 3.0 * r_n - 2.0 * g_n
        ys = 1.5 * r_n + g_n - 1.5 * b_n
        std_y = np.std(ys)
        alpha = np.std(xs) / (std_y + 1e-6)
        s = xs - alpha * ys

        pulse = self._butter_bandpass(s)
        freqs, psd = welch(pulse, fs=self.fps, nperseg=min(len(pulse), 256))
        valid_idx = np.where((freqs >= self.lowcut) & (freqs <= self.highcut))[0]

        if len(valid_idx) == 0:
            return None, None, None

        peak_freq = freqs[valid_idx][np.argmax(psd[valid_idx])]
        heart_rate_bpm = float(peak_freq * 60.0)

        # Stress Level 추정치 (HRV 대용)
        stress_level = min(100.0, max(10.0, (heart_rate_bpm - 50.0) * 1.2))

        return round(heart_rate_bpm, 1), round(stress_level, 1), 0.95
