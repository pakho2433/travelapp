import * as THREE from 'https://esm.sh/three@0.160.0';
import { OrbitControls } from 'https://esm.sh/three@0.160.0/examples/jsm/controls/OrbitControls.js';

const STORAGE_KEY = 'travel-globe-web-records-v1';
const EARTH_RADIUS = 1.55;

const SAMPLE_PLACES = [
  {
    id: 'sample-hong-kong',
    placeName: 'Hong Kong',
    country: 'Hong Kong',
    city: 'Hong Kong',
    latitude: 22.3193,
    longitude: 114.1694,
    date: '2025-07-28',
    note: '維港夜景、城市步行和美食回憶。',
    photoUrl: 'https://images.unsplash.com/photo-1536599018102-9f803c140fc1?auto=format&fit=crop&w=900&q=80'
  },
  {
    id: 'sample-tokyo',
    placeName: 'Tokyo',
    country: 'Japan',
    city: 'Tokyo',
    latitude: 35.6762,
    longitude: 139.6503,
    date: '2024-12-20',
    note: '東京街景、咖啡店、拉麵和夜晚燈光。',
    photoUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=900&q=80'
  },
  {
    id: 'sample-taipei',
    placeName: 'Taipei',
    country: 'Taiwan',
    city: 'Taipei',
    latitude: 25.033,
    longitude: 121.5654,
    date: '2025-08-01',
    note: '台北 101、夜市和輕鬆旅行日。',
    photoUrl: 'https://images.unsplash.com/photo-1470004914212-05527e49370b?auto=format&fit=crop&w=900&q=80'
  }
];

const elements = {
  globeContainer: document.getElementById('globeContainer'),
  detailPanel: document.getElementById('detailPanel'),
  placeList: document.getElementById('placeList'),
  placeCount: document.getElementById('placeCount'),
  countryCount: document.getElementById('countryCount'),
  resetButton: document.getElementById('resetButton'),
  form: document.getElementById('placeForm'),
  formError: document.getElementById('formError')
};

let places = loadPlaces();
let activeId = places[0]?.id || null;
let scene;
let camera;
let renderer;
let controls;
let earthGroup;
let pinGroup;
let raycaster;
let pointer;
let targetCameraPosition = null;
const pinObjects = new Map();

initScene();
renderUI();
animate();

window.addEventListener('resize', resizeRenderer);
elements.resetButton.addEventListener('click', resetSamples);
elements.form.addEventListener('submit', handleAddPlace);
elements.globeContainer.addEventListener('pointermove', updatePointer);
elements.globeContainer.addEventListener('click', handleGlobeClick);

function loadPlaces() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [...SAMPLE_PLACES];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [...SAMPLE_PLACES];
  } catch {
    return [...SAMPLE_PLACES];
  }
}

function savePlaces() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(places));
}

function initScene() {
  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(45, 1, 0.1, 100);
  camera.position.set(0, 0, 4.6);

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  elements.globeContainer.appendChild(renderer.domElement);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.06;
  controls.enablePan = false;
  controls.minDistance = 2.6;
  controls.maxDistance = 7.2;
  controls.rotateSpeed = 0.55;
  controls.zoomSpeed = 0.72;
  controls.autoRotate = true;
  controls.autoRotateSpeed = 0.25;

  raycaster = new THREE.Raycaster();
  pointer = new THREE.Vector2();

  scene.add(new THREE.AmbientLight(0x9fdcff, 0.7));

  const sun = new THREE.DirectionalLight(0xffffff, 2.3);
  sun.position.set(4, 3, 5);
  scene.add(sun);

  const fill = new THREE.PointLight(0x35c9ff, 1.4);
  fill.position.set(-4, -2, -3);
  scene.add(fill);

  earthGroup = new THREE.Group();
  scene.add(earthGroup);

  pinGroup = new THREE.Group();
  scene.add(pinGroup);

  createStars();
  createEarth();
  refreshPins();
  resizeRenderer();
}

function createStars() {
  const geometry = new THREE.BufferGeometry();
  const positions = [];

  for (let i = 0; i < 2200; i++) {
    positions.push(
      (Math.random() - 0.5) * 95,
      (Math.random() - 0.5) * 95,
      (Math.random() - 0.5) * 95
    );
  }

  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));

  const material = new THREE.PointsMaterial({
    color: 0xffffff,
    size: 0.045,
    transparent: true,
    opacity: 0.8
  });

  scene.add(new THREE.Points(geometry, material));
}

function createEarth() {
  const earthTexture = createEarthTexture();

  const earth = new THREE.Mesh(
    new THREE.SphereGeometry(EARTH_RADIUS, 96, 96),
    new THREE.MeshStandardMaterial({
      map: earthTexture,
      roughness: 0.68,
      metalness: 0.05,
      emissive: 0x062e45,
      emissiveIntensity: 0.24
    })
  );

  const grid = new THREE.Mesh(
    new THREE.SphereGeometry(EARTH_RADIUS + 0.006, 48, 48),
    new THREE.MeshBasicMaterial({
      color: 0x9fefff,
      transparent: true,
      opacity: 0.08,
      wireframe: true,
      depthWrite: false
    })
  );

  const glow = new THREE.Mesh(
    new THREE.SphereGeometry(EARTH_RADIUS + 0.045, 96, 96),
    new THREE.MeshBasicMaterial({
      color: 0x8fe7ff,
      transparent: true,
      opacity: 0.07,
      depthWrite: false,
      side: THREE.BackSide
    })
  );

  earthGroup.add(earth, grid, glow);
}

function createEarthTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = 2048;
  canvas.height = 1024;
  const ctx = canvas.getContext('2d');

  const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
  gradient.addColorStop(0, '#06203e');
  gradient.addColorStop(0.45, '#0b5f78');
  gradient.addColorStop(1, '#04314f');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const toXY = (lon, lat) => ({
    x: ((lon + 180) / 360) * canvas.width,
    y: ((90 - lat) / 180) * canvas.height
  });

  const drawLand = (lon, lat, rxDegree, ryDegree, rotation = 0, alpha = 0.88) => {
    const { x, y } = toXY(lon, lat);
    const rx = (rxDegree / 360) * canvas.width;
    const ry = (ryDegree / 180) * canvas.height;
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(rotation);
    ctx.beginPath();
    ctx.ellipse(0, 0, rx, ry, 0, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(95, 222, 169, ${alpha})`;
    ctx.fill();
    ctx.restore();
  };

  drawLand(-100, 45, 32, 22, -0.35);
  drawLand(-80, 15, 24, 30, 0.45);
  drawLand(-60, -18, 18, 33, -0.1);
  drawLand(20, 5, 26, 36, -0.12);
  drawLand(15, 50, 25, 13, 0.05);
  drawLand(75, 47, 48, 22, 0.1);
  drawLand(105, 20, 35, 25, -0.2);
  drawLand(135, -25, 18, 12, 0.15);
  drawLand(-42, 72, 18, 10, -0.25);

  for (let i = 0; i < 140; i++) {
    drawLand(
      -180 + Math.random() * 360,
      -60 + Math.random() * 120,
      2 + Math.random() * 5,
      1 + Math.random() * 4,
      Math.random() * 3,
      0.24
    );
  }

  ctx.strokeStyle = 'rgba(255,255,255,0.08)';
  ctx.lineWidth = 1;

  for (let lat = -60; lat <= 60; lat += 30) {
    const y = ((90 - lat) / 180) * canvas.height;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y);
    ctx.stroke();
  }

  for (let lon = -180; lon <= 180; lon += 30) {
    const x = ((lon + 180) / 360) * canvas.width;
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvas.height);
    ctx.stroke();
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 8;
  texture.needsUpdate = true;
  return texture;
}

function latLngToVector3(latitude, longitude, radius = EARTH_RADIUS) {
  const lat = THREE.MathUtils.degToRad(latitude);
  const lng = THREE.MathUtils.degToRad(longitude);

  return new THREE.Vector3(
    radius * Math.cos(lat) * Math.sin(lng),
    radius * Math.sin(lat),
    radius * Math.cos(lat) * Math.cos(lng)
  );
}

function refreshPins() {
  pinGroup.clear();
  pinObjects.clear();

  places.forEach((place) => {
    const normal = latLngToVector3(place.latitude, place.longitude, 1).normalize();
    const position = normal.clone().multiplyScalar(EARTH_RADIUS + 0.075);

    const pin = new THREE.Group();
    pin.position.copy(position);
    pin.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), normal);
    pin.userData.placeId = place.id;

    const ball = new THREE.Mesh(
      new THREE.SphereGeometry(0.06, 28, 28),
      new THREE.MeshStandardMaterial({
        color: 0xff425f,
        emissive: 0xff123d,
        emissiveIntensity: 2.35,
        roughness: 0.35
      })
    );
    ball.position.y = 0.04;
    ball.userData.placeId = place.id;

    const stem = new THREE.Mesh(
      new THREE.CylinderGeometry(0.013, 0.013, 0.15, 16),
      new THREE.MeshStandardMaterial({
        color: 0xff3154,
        emissive: 0xff193b,
        emissiveIntensity: 1.4
      })
    );
    stem.position.y = -0.035;
    stem.userData.placeId = place.id;

    const glow = new THREE.Mesh(
      new THREE.SphereGeometry(0.13, 24, 24),
      new THREE.MeshBasicMaterial({
        color: 0xff365e,
        transparent: true,
        opacity: 0.16,
        depthWrite: false
      })
    );
    glow.position.y = 0.04;
    glow.userData.placeId = place.id;

    pin.add(ball, stem, glow);
    pinGroup.add(pin);
    pinObjects.set(place.id, { pin, ball, glow });
  });
}

function resizeRenderer() {
  const rect = elements.globeContainer.getBoundingClientRect();
  const width = Math.max(1, rect.width);
  const height = Math.max(1, rect.height);
  camera.aspect = width / height;
  camera.updateProjectionMatrix();
  renderer.setSize(width, height, false);
}

function updatePointer(event) {
  const rect = elements.globeContainer.getBoundingClientRect();
  pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
}

function handleGlobeClick(event) {
  updatePointer(event);
  raycaster.setFromCamera(pointer, camera);
  const intersects = raycaster.intersectObjects(pinGroup.children, true);

  if (!intersects.length) return;

  const placeId = intersects[0].object.userData.placeId;
  const place = places.find((item) => item.id === placeId);
  if (place) selectPlace(place);
}

function selectPlace(place) {
  activeId = place.id;
  const focusPosition = latLngToVector3(place.latitude, place.longitude, 4.15);
  targetCameraPosition = focusPosition;
  controls.autoRotate = false;
  renderUI();
}

function handleAddPlace(event) {
  event.preventDefault();
  const form = event.target;

  const latitude = Number(form.latitude.value);
  const longitude = Number(form.longitude.value);

  if (!form.placeName.value.trim()) return showError('請填寫地點名稱。');
  if (!form.country.value.trim()) return showError('請填寫國家 / 地區。');
  if (!form.city.value.trim()) return showError('請填寫城市。');
  if (Number.isNaN(latitude) || latitude < -90 || latitude > 90) return showError('Latitude 必須是 -90 至 90 之間的數字。');
  if (Number.isNaN(longitude) || longitude < -180 || longitude > 180) return showError('Longitude 必須是 -180 至 180 之間的數字。');

  const newPlace = {
    id: `place-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    placeName: form.placeName.value.trim(),
    country: form.country.value.trim(),
    city: form.city.value.trim(),
    latitude,
    longitude,
    date: form.date.value || new Date().toISOString().slice(0, 10),
    note: form.note.value.trim(),
    photoUrl: form.photoUrl.value.trim()
  };

  places = [newPlace, ...places];
  savePlaces();
  form.reset();
  hideError();
  refreshPins();
  selectPlace(newPlace);
}

function resetSamples() {
  places = [...SAMPLE_PLACES];
  savePlaces();
  activeId = places[0].id;
  refreshPins();
  selectPlace(places[0]);
}

function deletePlace(placeId) {
  places = places.filter((place) => place.id !== placeId);
  savePlaces();
  if (activeId === placeId) activeId = places[0]?.id || null;
  refreshPins();
  renderUI();
}

function showError(message) {
  elements.formError.textContent = message;
  elements.formError.hidden = false;
}

function hideError() {
  elements.formError.textContent = '';
  elements.formError.hidden = true;
}

function renderUI() {
  elements.placeCount.textContent = String(places.length);
  elements.countryCount.textContent = String(new Set(places.map((place) => place.country.trim().toLowerCase()).filter(Boolean)).size);

  const activePlace = places.find((place) => place.id === activeId) || null;
  renderDetail(activePlace);
  renderList();
}

function renderDetail(place) {
  if (!place) {
    elements.detailPanel.className = 'detail-panel empty';
    elements.detailPanel.innerHTML = '<p>請點擊地球上的圖釘，或在列表選擇一個地點。</p>';
    return;
  }

  elements.detailPanel.className = 'detail-panel';
  elements.detailPanel.innerHTML = `
    ${place.photoUrl ? `<img class="trip-photo" src="${escapeAttribute(place.photoUrl)}" alt="${escapeAttribute(place.placeName)}" loading="lazy" />` : '<div class="photo-placeholder">No Photo</div>'}
    <div class="detail-heading">
      <div>
        <h3>${escapeHTML(place.placeName)}</h3>
        <p>${escapeHTML(place.city)}・${escapeHTML(place.country)}</p>
      </div>
      <button class="danger-button" type="button" data-delete-detail="${escapeAttribute(place.id)}">刪除</button>
    </div>
    <div class="info-grid">
      <div class="info-box"><span>到訪日期</span><strong>${escapeHTML(place.date || '未填寫')}</strong></div>
      <div class="info-box"><span>Latitude</span><strong>${Number(place.latitude).toFixed(4)}</strong></div>
      <div class="info-box"><span>Longitude</span><strong>${Number(place.longitude).toFixed(4)}</strong></div>
    </div>
    <p class="note-box">${escapeHTML(place.note || '未加入備註。')}</p>
  `;

  const deleteButton = elements.detailPanel.querySelector('[data-delete-detail]');
  deleteButton.addEventListener('click', () => deletePlace(place.id));
}

function renderList() {
  if (!places.length) {
    elements.placeList.innerHTML = '<p class="empty-list">暫時未有旅行記錄。</p>';
    return;
  }

  elements.placeList.innerHTML = places.map((place) => `
    <button class="place-item ${place.id === activeId ? 'active' : ''}" type="button" data-place-id="${escapeAttribute(place.id)}">
      <span class="pin-dot"></span>
      <span>
        <strong>${escapeHTML(place.placeName)}</strong>
        <small>${escapeHTML(place.city)}・${escapeHTML(place.country)}</small>
      </span>
      <span class="place-date">${escapeHTML(place.date || '')}</span>
    </button>
  `).join('');

  elements.placeList.querySelectorAll('[data-place-id]').forEach((button) => {
    button.addEventListener('click', () => {
      const place = places.find((item) => item.id === button.dataset.placeId);
      if (place) selectPlace(place);
    });
  });
}

function animate() {
  requestAnimationFrame(animate);

  const elapsed = performance.now() / 1000;
  pinObjects.forEach(({ pin, ball, glow }, placeId) => {
    const isActive = placeId === activeId;
    const pulse = Math.sin(elapsed * 3.2) * 0.08;
    const scale = isActive ? 1.35 + pulse : 1 + pulse * 0.5;
    pin.scale.setScalar(scale);
    ball.material.color.set(isActive ? 0xffef9a : 0xff425f);
    ball.material.emissive.set(isActive ? 0xffd35c : 0xff123d);
    glow.material.opacity = isActive ? 0.24 : 0.16;
  });

  if (targetCameraPosition) {
    camera.position.lerp(targetCameraPosition, 0.075);
    camera.lookAt(0, 0, 0);
    if (camera.position.distanceTo(targetCameraPosition) < 0.035) {
      targetCameraPosition = null;
    }
  }

  controls.update();
  renderer.render(scene, camera);
}

function escapeHTML(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function escapeAttribute(value) {
  return escapeHTML(value);
}
