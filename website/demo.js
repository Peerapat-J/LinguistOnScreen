(function () {
    const demoData = {
        en: {
            segments: [
                {
                    src: '인공지능과 번역의 미래',
                    translation: 'The Future of AI and Translation',
                    tag: 'h3',
                },
                {
                    src: '인공지능(AI) 기술은 우리가 소통하는 방식을 근본적으로 바꾸고 있습니다. 특히 자연어 처리(NLP) 분야의 발전은 기계 번역의 품질을 획기적으로 향상시켰습니다.',
                    translation: 'Artificial intelligence (AI) technology is fundamentally changing how we communicate. Advances in natural language processing (NLP) have dramatically improved the quality of machine translation.',
                    tag: 'p',
                },
                {
                    src: 'Apple의 온디바이스 번역 기술은 사용자의 프라이버시를 보호하면서도 높은 번역 품질을 제공합니다. 모든 처리가 기기 내에서 이루어지므로 인터넷 연결 없이도 사용할 수 있습니다.',
                    translation: "Apple's on-device translation technology provides high-quality translations while protecting user privacy. All processing happens on-device, so it works without an internet connection.",
                    tag: 'p',
                },
            ],
            recognizing: 'Recognizing...',
            translating: 'Translating...',
        },
        ko: {
            segments: [
                {
                    src: 'The Future of AI and Translation',
                    translation: '인공지능과 번역의 미래',
                    tag: 'h3',
                },
                {
                    src: 'Artificial intelligence (AI) technology is fundamentally changing how we communicate. Advances in natural language processing (NLP) have dramatically improved the quality of machine translation.',
                    translation: '인공지능(AI) 기술은 우리가 소통하는 방식을 근본적으로 바꾸고 있습니다. 특히 자연어 처리(NLP) 분야의 발전은 기계 번역의 품질을 획기적으로 향상시켰습니다.',
                    tag: 'p',
                },
                {
                    src: "Apple's on-device translation technology provides high-quality translations while protecting user privacy. All processing happens on-device, so it works without an internet connection.",
                    translation: 'Apple의 온디바이스 번역 기술은 사용자의 프라이버시를 보호하면서도 높은 번역 품질을 제공합니다. 모든 처리가 기기 내에서 이루어지므로 인터넷 연결 없이도 사용할 수 있습니다.',
                    tag: 'p',
                },
            ],
            recognizing: '인식 중...',
            translating: '번역 중...',
        },
    };

    let isDragging = false;
    let startX = 0, startY = 0;
    let animationPlayed = false;
    let busy = false;

    function getLang() {
        return localStorage.getItem('lang') || (navigator.language.startsWith('ko') ? 'ko' : 'en');
    }

    function buildText(lang) {
        const data = demoData[lang];
        return data.segments.map((seg, i) => {
            if (seg.tag === 'h3') {
                return '<h3 class="demo-seg" data-seg="' + i + '" style="margin-bottom:14px;font-size:1.05rem;color:#e4e4e7;">' + seg.src + '</h3>';
            }
            return '<p class="demo-seg" data-seg="' + i + '" style="margin-top:12px;">' + seg.src + '</p>';
        }).join('');
    }

    function rectsOverlap(a, b) {
        return !(a.right < b.left || a.left > b.right || a.bottom < b.top || a.top > b.bottom);
    }

    function getSelectedTranslation(content, selection) {
        const lang = getLang();
        const data = demoData[lang];
        const contentRect = content.getBoundingClientRect();

        // Selection rect in viewport coords
        const selRect = {
            left: contentRect.left + parseInt(selection.style.left),
            top: contentRect.top + parseInt(selection.style.top),
            right: contentRect.left + parseInt(selection.style.left) + parseInt(selection.style.width),
            bottom: contentRect.top + parseInt(selection.style.top) + parseInt(selection.style.height),
        };

        const segments = content.querySelectorAll('.demo-seg');
        const matched = [];
        segments.forEach((el) => {
            const segRect = el.getBoundingClientRect();
            if (rectsOverlap(selRect, segRect)) {
                const idx = parseInt(el.dataset.seg);
                matched.push(data.segments[idx].translation);
            }
        });

        return matched.length > 0 ? matched.join('\n\n') : data.segments.map(s => s.translation).join('\n\n');
    }

    function initDemo() {
        const content = document.getElementById('demo-content');
        const textEl = document.getElementById('demo-text');
        const selection = document.getElementById('demo-selection');
        const popup = document.getElementById('demo-popup');
        const hint = document.getElementById('demo-hint');
        if (!content) return;

        updateDemoText();

        const observer = new MutationObserver(updateDemoText);
        observer.observe(document.documentElement, { attributes: true, attributeFilter: ['lang'] });

        // Auto-play on scroll
        const io = new IntersectionObserver((entries) => {
            if (entries[0].isIntersecting && !animationPlayed) {
                animationPlayed = true;
                setTimeout(() => autoPlay(content, selection, popup, hint), 600);
            }
        }, { threshold: 0.5 });
        io.observe(content);

        // Manual drag
        content.addEventListener('mousedown', (e) => {
            if (busy) return;
            resetDemo(selection, popup);
            hint.style.opacity = '0';
            const rect = content.getBoundingClientRect();
            startX = e.clientX - rect.left;
            startY = e.clientY - rect.top;
            isDragging = true;
            selection.style.display = 'block';
            selection.style.left = startX + 'px';
            selection.style.top = startY + 'px';
            selection.style.width = '0';
            selection.style.height = '0';
        });

        content.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            const rect = content.getBoundingClientRect();
            const curX = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
            const curY = Math.max(0, Math.min(e.clientY - rect.top, rect.height));
            selection.style.left = Math.min(startX, curX) + 'px';
            selection.style.top = Math.min(startY, curY) + 'px';
            selection.style.width = Math.abs(curX - startX) + 'px';
            selection.style.height = Math.abs(curY - startY) + 'px';
        });

        document.addEventListener('mouseup', () => {
            if (!isDragging) return;
            isDragging = false;
            const w = parseInt(selection.style.width);
            const h = parseInt(selection.style.height);
            if (w < 20 || h < 20) {
                resetDemo(selection, popup);
                hint.style.opacity = '1';
                return;
            }
            showPopup(content, selection, popup);
        });

        // Click outside to reset
        document.addEventListener('mousedown', (e) => {
            if (!popup.style.display || popup.style.display === 'none') return;
            if (content.contains(e.target)) return;
            resetDemo(selection, popup);
            hint.style.opacity = '1';
        });
    }

    function updateDemoText() {
        const textEl = document.getElementById('demo-text');
        if (!textEl) return;
        textEl.innerHTML = buildText(getLang());
    }

    function resetDemo(selection, popup) {
        selection.style.display = 'none';
        popup.style.display = 'none';
        popup.classList.remove('visible');
        busy = false;
    }

    function showPopup(content, selection, popup) {
        busy = true;
        const lang = getLang();
        const data = demoData[lang];
        const statusEl = popup.querySelector('.demo-popup-status');
        const resultEl = popup.querySelector('.demo-popup-result');
        const actionsEl = popup.querySelector('.demo-popup-actions');
        const translatedText = getSelectedTranslation(content, selection);

        // Position popup below selection
        const selLeft = parseInt(selection.style.left);
        const selTop = parseInt(selection.style.top);
        const selHeight = parseInt(selection.style.height);
        const contentRect = content.getBoundingClientRect();

        popup.style.left = selLeft + 'px';
        popup.style.top = (selTop + selHeight + 8) + 'px';
        popup.style.display = 'block';
        statusEl.textContent = data.recognizing;
        resultEl.textContent = '';
        actionsEl.style.display = 'none';
        popup.classList.add('visible');

        setTimeout(() => {
            statusEl.textContent = data.translating;
        }, 700);

        setTimeout(() => {
            statusEl.textContent = '';
            resultEl.textContent = translatedText;
            actionsEl.style.display = 'flex';
            busy = false;

            // Reposition if overflows
            requestAnimationFrame(() => {
                const pRect = popup.getBoundingClientRect();
                if (pRect.right > contentRect.right - 8) {
                    popup.style.left = Math.max(8, contentRect.width - pRect.width - 8) + 'px';
                }
                if (pRect.bottom > contentRect.bottom + 60) {
                    popup.style.top = (selTop - popup.offsetHeight - 8) + 'px';
                }
            });
        }, 1400);
    }

    function autoPlay(content, selection, popup, hint) {
        if (busy) return;
        hint.style.opacity = '0';

        // Target the second segment (first paragraph)
        const secondSeg = content.querySelector('[data-seg="1"]');
        if (!secondSeg) return;

        const contentRect = content.getBoundingClientRect();
        const segRect = secondSeg.getBoundingClientRect();
        const sx = segRect.left - contentRect.left - 4;
        const sy = segRect.top - contentRect.top - 4;
        const ex = sx + segRect.width + 8;
        const ey = sy + segRect.height + 8;
        const duration = 800;
        const startTime = performance.now();

        selection.style.display = 'block';
        selection.style.left = sx + 'px';
        selection.style.top = sy + 'px';
        selection.style.width = '0';
        selection.style.height = '0';

        function animate(now) {
            const elapsed = now - startTime;
            const t = Math.min(elapsed / duration, 1);
            const ease = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
            selection.style.width = (ex - sx) * ease + 'px';
            selection.style.height = (ey - sy) * ease + 'px';
            if (t < 1) {
                requestAnimationFrame(animate);
            } else {
                showPopup(content, selection, popup);
                setTimeout(() => {
                    hint.style.opacity = '1';
                }, 4000);
            }
        }
        requestAnimationFrame(animate);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initDemo);
    } else {
        initDemo();
    }
})();
