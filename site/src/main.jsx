import React, { useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import * as THREE from "three";
import "./styles.css";

const repoUrl = "https://github.com/thanhphuchuynh/kindle-shared";
const releasesUrl = `${repoUrl}/releases`;

function roundedBoxGeometry(width, height, depth, radius, segments = 5) {
  const shape = new THREE.Shape();
  const x = -width / 2;
  const y = -height / 2;
  shape.moveTo(x + radius, y);
  shape.lineTo(x + width - radius, y);
  shape.quadraticCurveTo(x + width, y, x + width, y + radius);
  shape.lineTo(x + width, y + height - radius);
  shape.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  shape.lineTo(x + radius, y + height);
  shape.quadraticCurveTo(x, y + height, x, y + height - radius);
  shape.lineTo(x, y + radius);
  shape.quadraticCurveTo(x, y, x + radius, y);
  return new THREE.ExtrudeGeometry(shape, {
    depth,
    bevelEnabled: true,
    bevelSize: Math.min(radius * 0.22, 0.035),
    bevelThickness: 0.025,
    bevelSegments: segments,
  }).center();
}

function makeTextSprite(text, options = {}) {
  const canvas = document.createElement("canvas");
  const width = options.width || 640;
  const height = options.height || 160;
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = options.bg || "rgba(0,0,0,0)";
  ctx.fillRect(0, 0, width, height);
  ctx.font = `${options.weight || 700} ${options.size || 42}px ${options.font || "Georgia"}`;
  ctx.fillStyle = options.color || "#1f211f";
  ctx.textBaseline = "middle";
  ctx.textAlign = options.align || "center";
  const lines = text.split("\n");
  const lineHeight = options.lineHeight || 46;
  lines.forEach((line, index) => {
    ctx.fillText(line, width / 2, height / 2 + (index - (lines.length - 1) / 2) * lineHeight);
  });
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const material = new THREE.SpriteMaterial({ map: texture, transparent: true });
  const sprite = new THREE.Sprite(material);
  sprite.scale.set(options.scaleX || 2.4, options.scaleY || 0.6, 1);
  return sprite;
}

function createArc(radius, y, color) {
  const points = [];
  for (let i = 0; i <= 52; i += 1) {
    const t = Math.PI * 0.18 + (Math.PI * 0.64 * i) / 52;
    points.push(new THREE.Vector3(Math.cos(t) * radius, y + Math.sin(t) * radius * 0.42, 0));
  }
  const geometry = new THREE.BufferGeometry().setFromPoints(points);
  const material = new THREE.LineBasicMaterial({ color, transparent: true, opacity: 0.78 });
  return new THREE.Line(geometry, material);
}

function Diorama() {
  const mountRef = useRef(null);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return undefined;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#ede9dc");

    const camera = new THREE.PerspectiveCamera(34, mount.clientWidth / mount.clientHeight, 0.1, 100);
    camera.position.set(-0.7, 3.6, 8.9);
    camera.lookAt(0.72, 0.08, 0);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(mount.clientWidth, mount.clientHeight);
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    mount.appendChild(renderer.domElement);

    const ambient = new THREE.HemisphereLight("#fffaf0", "#8c8a80", 2.7);
    scene.add(ambient);
    const key = new THREE.DirectionalLight("#ffffff", 3.1);
    key.position.set(-3, 5, 5);
    scene.add(key);

    const ink = new THREE.MeshStandardMaterial({ color: "#191a17", roughness: 0.92, metalness: 0.02 });
    const graphite = new THREE.MeshStandardMaterial({ color: "#3e4039", roughness: 0.88, metalness: 0.03 });
    const paper = new THREE.MeshStandardMaterial({ color: "#f4f0e2", roughness: 0.96, metalness: 0.01 });
    const screen = new THREE.MeshStandardMaterial({ color: "#d7d1bd", roughness: 0.85, metalness: 0.01 });
    const blue = new THREE.MeshStandardMaterial({ color: "#2b6f8f", roughness: 0.82, metalness: 0.02 });
    const green = new THREE.MeshStandardMaterial({ color: "#2f7d4a", roughness: 0.82, metalness: 0.02 });
    const bookMats = ["#22231f", "#6a4f3a", "#355b64", "#7b7c6f"].map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.9 }));

    const floor = new THREE.Mesh(new THREE.CircleGeometry(5.5, 96), new THREE.MeshStandardMaterial({ color: "#dfd9c8", roughness: 1 }));
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -0.82;
    scene.add(floor);

    const desk = new THREE.Mesh(roundedBoxGeometry(5.5, 0.24, 3.1, 0.18), paper);
    desk.rotation.x = -Math.PI / 2;
    desk.position.y = -0.62;
    scene.add(desk);

    const laptopBase = new THREE.Mesh(roundedBoxGeometry(1.95, 0.16, 1.25, 0.08), graphite);
    laptopBase.position.set(-1.95, -0.32, 0.12);
    laptopBase.rotation.x = -Math.PI / 2;
    scene.add(laptopBase);

    const laptopScreen = new THREE.Mesh(roundedBoxGeometry(1.85, 1.2, 0.12, 0.09), ink);
    laptopScreen.position.set(-1.95, 0.33, -0.48);
    laptopScreen.rotation.x = -0.25;
    scene.add(laptopScreen);

    const laptopPanel = new THREE.Mesh(roundedBoxGeometry(1.55, 0.84, 0.04, 0.05), screen);
    laptopPanel.position.set(-1.95, 0.37, -0.55);
    laptopPanel.rotation.x = -0.25;
    scene.add(laptopPanel);

    const folderLabel = makeTextSprite("~/Books", { size: 48, weight: 800, scaleX: 1.2, scaleY: 0.32, color: "#232520" });
    folderLabel.position.set(-1.95, 0.5, -0.66);
    scene.add(folderLabel);

    for (let i = 0; i < 5; i += 1) {
      const book = new THREE.Mesh(roundedBoxGeometry(0.52, 0.12, 0.78, 0.03), bookMats[i % bookMats.length]);
      book.position.set(-2.55 + i * 0.16, -0.22 + i * 0.09, 1.15 - i * 0.02);
      book.rotation.set(-Math.PI / 2, 0.08, -0.12);
      scene.add(book);
    }

    const kindle = new THREE.Mesh(roundedBoxGeometry(1.25, 1.85, 0.14, 0.11), ink);
    kindle.position.set(2.05, 0.25, 0.35);
    kindle.rotation.set(-0.12, -0.28, 0.03);
    scene.add(kindle);

    const kindleScreen = new THREE.Mesh(roundedBoxGeometry(1.02, 1.52, 0.04, 0.06), paper);
    kindleScreen.position.set(2.0, 0.3, 0.48);
    kindleScreen.rotation.set(-0.12, -0.28, 0.03);
    scene.add(kindleScreen);

    const kindleList = makeTextSprite("Kindle Share\nBo Gia.azw3\nDesign.pdf\nReady", {
      width: 520,
      height: 300,
      size: 35,
      lineHeight: 50,
      weight: 800,
      scaleX: 0.86,
      scaleY: 0.5,
      color: "#232520",
    });
    kindleList.position.set(2.0, 0.38, 0.57);
    scene.add(kindleList);

    const router = new THREE.Mesh(roundedBoxGeometry(0.74, 0.18, 0.55, 0.07), blue);
    router.position.set(0, -0.26, 1.04);
    router.rotation.x = -Math.PI / 2;
    scene.add(router);

    const urlLabel = makeTextSprite("192.168.1.7:8787", {
      width: 760,
      height: 110,
      size: 45,
      weight: 800,
      font: "monospace",
      scaleX: 1.8,
      scaleY: 0.32,
      color: "#1f211f",
    });
    urlLabel.position.set(0, 1.45, -0.1);
    scene.add(urlLabel);

    const arcs = [0.9, 1.25, 1.62].map((radius, index) => {
      const arc = createArc(radius, 0.15 + index * 0.1, index === 1 ? "#2b6f8f" : "#242521");
      arc.position.set(0.08, 0.3, 0.22);
      arc.rotation.x = -0.18;
      scene.add(arc);
      return arc;
    });

    const particles = [];
    const particleGeometry = new THREE.SphereGeometry(0.045, 16, 16);
    for (let i = 0; i < 18; i += 1) {
      const p = new THREE.Mesh(particleGeometry, i % 3 === 0 ? green : blue);
      p.userData.offset = i / 18;
      scene.add(p);
      particles.push(p);
    }

    let frameId = 0;
    const clock = new THREE.Clock();

    const resize = () => {
      const width = mount.clientWidth;
      const height = mount.clientHeight;
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer.setSize(width, height);
    };

    const animate = () => {
      const elapsed = clock.getElapsedTime();
      const scroll = Math.min(window.scrollY / Math.max(window.innerHeight, 1), 1);
      camera.position.x = THREE.MathUtils.lerp(camera.position.x, -0.7 + scroll * 0.7, 0.03);
      camera.position.y = THREE.MathUtils.lerp(camera.position.y, 3.75 - scroll * 0.55, 0.03);
      camera.lookAt(0.72 + scroll * 0.18, 0.12, 0);

      arcs.forEach((arc, index) => {
        arc.material.opacity = 0.35 + Math.sin(elapsed * 2.4 + index) * 0.18 + 0.35;
      });

      particles.forEach((particle) => {
        const t = (elapsed * 0.18 + particle.userData.offset) % 1;
        const eased = 0.5 - Math.cos(t * Math.PI) / 2;
        particle.position.set(
          THREE.MathUtils.lerp(-1.52, 1.58, eased),
          0.02 + Math.sin(t * Math.PI) * 1.25,
          0.45 + Math.sin(t * Math.PI * 2) * 0.18
        );
        particle.scale.setScalar(0.7 + Math.sin(t * Math.PI) * 0.8);
      });

      router.rotation.z = Math.sin(elapsed * 0.7) * 0.025;
      frameId = requestAnimationFrame(animate);
      renderer.render(scene, camera);
    };

    window.addEventListener("resize", resize);
    resize();
    animate();

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener("resize", resize);
      mount.removeChild(renderer.domElement);
      scene.traverse((object) => {
        if (object.geometry) object.geometry.dispose();
        if (object.material) {
          if (Array.isArray(object.material)) object.material.forEach((material) => material.dispose());
          else object.material.dispose();
        }
      });
      renderer.dispose();
    };
  }, []);

  return <div className="diorama" ref={mountRef} aria-hidden="true" />;
}

function App() {
  const [step, setStep] = useState(0);
  const steps = [
    ["Choose a folder", "Point Kindle Share at the books already on your computer."],
    ["Start local sharing", "A tiny server opens inside your home Wi-Fi network."],
    ["Open the Kindle URL", "Type the local address into the Kindle browser."],
    ["Download", "Tap a title and let Kindle pull the file directly."],
  ];

  useEffect(() => {
    const timer = window.setInterval(() => setStep((current) => (current + 1) % steps.length), 2600);
    return () => window.clearInterval(timer);
  }, [steps.length]);

  return (
    <>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="Kindle Share home">
          <img src="/assets/logo.png" alt="" />
          <span>Kindle Share</span>
        </a>
        <nav aria-label="Primary">
          <a href="#how">How it works</a>
          <a href="#local">Why local</a>
          <a href="#download">Download</a>
        </nav>
      </header>

      <main id="top">
        <section className="hero" aria-label="Kindle Share overview">
          <Diorama />
          <div className="hero-copy">
            <h1>A local book server for Kindle.</h1>
            <p>Your books are already in the room. Share a folder from your computer, open one local address on Kindle, and download. No cloud. No account. No cable.</p>
            <div className="hero-actions">
              <a className="button primary" href={releasesUrl}>Download</a>
              <a className="button secondary" href={repoUrl}>View source</a>
            </div>
          </div>
          <div className="hero-note" aria-label="Local network path">
            <span>Mac / PC</span>
            <strong>local Wi-Fi</strong>
            <span>Kindle Browser</span>
          </div>
        </section>

        <section id="how" className="story">
          <div className="section-copy">
            <h2>Four small steps. One room.</h2>
            <p>Kindle Share feels like a quiet e-ink manual because the workflow is that simple: folder, address, browser, download.</p>
          </div>
          <div className="step-list">
            {steps.map(([title, body], index) => (
              <button className={`step ${step === index ? "active" : ""}`} key={title} onClick={() => setStep(index)}>
                <span>0{index + 1}</span>
                <strong>{title}</strong>
                <small>{body}</small>
              </button>
            ))}
          </div>
        </section>

        <section id="local" className="local-band">
          <div className="local-copy">
            <h2>No cloud detour.</h2>
            <p>If the book is on your computer and the Kindle is beside you, the file does not need a trip across the internet.</p>
          </div>
          <div className="proof-grid">
            <article>
              <h3>No account</h3>
              <p>Open the app or CLI and serve only the folder you choose.</p>
            </article>
            <article>
              <h3>No cable</h3>
              <p>Kindle pulls from your computer over the same Wi-Fi.</p>
            </article>
            <article>
              <h3>No library lock-in</h3>
              <p>Use it beside Calibre, Send to Kindle, or plain folders.</p>
            </article>
          </div>
        </section>

        <section className="app-preview">
          <div className="section-copy">
            <h2>Native app, tiny server.</h2>
            <p>Use the polished macOS app, or run the CLI server for macOS, Linux, and Windows-oriented builds.</p>
          </div>
          <figure className="preview-frame">
            <img src="/assets/app-screenshot.png" alt="Kindle Share macOS app showing a local Kindle browser URL and shared books table" />
          </figure>
          <div className="cli-strip" aria-label="CLI example">
            <code>kindle-share serve --folder ~/Books --port 8787</code>
          </div>
        </section>

        <section id="download" className="download">
          <h2>Start with one folder.</h2>
          <p>Download the macOS app, or build the CLI from source when you want the portable server path.</p>
          <div className="hero-actions">
            <a className="button primary" href={releasesUrl}>Download Kindle Share</a>
            <a className="button secondary" href={repoUrl}>GitHub source</a>
          </div>
        </section>
      </main>

      <footer>
        <span>Kindle Share is an independent open-source tool.</span>
        <span>Local network only.</span>
      </footer>
    </>
  );
}

createRoot(document.getElementById("root")).render(<App />);
