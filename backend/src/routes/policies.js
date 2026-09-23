'use strict';

const { Router } = require('express');

// Demo content for the university project. It is intentionally static and
// public, so no customer data or administrative configuration is exposed.
const policies = {
  business: {
    title: 'Thông tin người bán',
    updatedAt: '2026-09-22',
    sections: [
      { heading: 'Đơn vị vận hành', body: 'EduMarket là dự án minh họa học phần CSE703102 – E-commerce, cung cấp khóa học và tài liệu số trong phạm vi bài tập đại học.' },
      { heading: 'Liên hệ demo', body: 'Liên hệ qua kênh do nhóm dự án công bố trong buổi bảo vệ. Không sử dụng thông tin này làm thông tin doanh nghiệp thực tế.' },
    ],
  },
  terms: {
    title: 'Điều khoản và điều kiện giao dịch',
    updatedAt: '2026-09-22',
    sections: [
      { heading: 'Sản phẩm số', body: 'Sau khi thanh toán được backend xác nhận, người học được cấp quyền truy cập khóa học/tài liệu tương ứng. Quyền truy cập có thể bị thu hồi bởi quản trị viên theo chính sách demo.' },
      { heading: 'Giá và thanh toán', body: 'Giá, khuyến mãi và trạng thái thanh toán được tính, kiểm tra và xác nhận tại máy chủ. COD là mô phỏng; VNPay chỉ dùng Sandbox.' },
    ],
  },
  refunds: {
    title: 'Chính sách đổi trả/hoàn tiền',
    updatedAt: '2026-09-22',
    sections: [
      { heading: 'Phạm vi demo', body: 'Dự án không xử lý hoàn tiền thực tế. Mọi yêu cầu minh họa được quản trị viên xem xét thủ công trong môi trường demo.' },
      { heading: 'Sản phẩm số', body: 'Với hệ thống triển khai thực tế, điều kiện hoàn tiền, thời hạn và quy trình xử lý phải được doanh nghiệp công bố và được tư vấn pháp lý trước khi áp dụng.' },
    ],
  },
  privacy: {
    title: 'Chính sách dữ liệu cá nhân',
    updatedAt: '2026-09-22',
    sections: [
      { heading: 'Dữ liệu xử lý', body: 'Dự án lưu thông tin tài khoản cần thiết để đăng nhập, giao dịch, cấp quyền học và cấp chứng nhận. Mật khẩu được băm; không lưu thông tin thẻ thanh toán.' },
      { heading: 'Bảo mật và giới hạn', body: 'Cookie phiên là HttpOnly và được ký; tài nguyên học tập/tệp tải xuống yêu cầu xác thực và quyền truy cập hợp lệ.' },
      { heading: 'Lưu ý pháp lý', body: 'Nội dung này chỉ phù hợp cho demo học thuật, không phải cam kết tuân thủ pháp luật. Triển khai sản xuất cần đánh giá pháp lý, thời hạn lưu trữ, quyền chủ thể dữ liệu và quy trình xử lý sự cố.' },
    ],
  },
};

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    success: true,
    data: {
      items: Object.entries(policies).map(([slug, policy]) => ({ slug, title: policy.title, updatedAt: policy.updatedAt })),
    },
  });
});

router.get('/:slug', (req, res) => {
  const policy = policies[req.params.slug];
  if (!policy) return res.status(404).json({ success: false, code: 'POLICY_NOT_FOUND', message: 'Policy content was not found.' });
  return res.json({ success: true, data: { slug: req.params.slug, ...policy, legalNotice: 'Implementation present; production legal review required.' } });
});

module.exports = router;
