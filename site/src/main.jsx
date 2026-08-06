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

function updateTextSprite(sprite, text, options = {}) {
  const oldMap = sprite.material.map;
  const next = makeTextSprite(text, options);
  sprite.material.map = next.material.map;
  sprite.material.needsUpdate = true;
  if (oldMap) oldMap.dispose();
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

function setObjectOpacity(object, opacity) {
  object.traverse((child) => {
    if (!child.material) return;
    const materials = Array.isArray(child.material) ? child.material : [child.material];
    materials.forEach((material) => {
      material.transparent = opacity < 1;
      material.opacity = opacity;
    });
  });
}

function Diorama({ activeStep }) {
  const mountRef = useRef(null);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return undefined;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#ede9dc");
    const state = { activeStep: 0 };
    mount.__kindleShareState = state;

    const camera = new THREE.PerspectiveCamera(34, mount.clientWidth / mount.clientHeight, 0.1, 100);
    camera.position.set(-0.9, 3.75, 8.9);
    camera.lookAt(0.64, 0.08, 0);

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

    const laptopGroup = new THREE.Group();
    laptopGroup.position.x = 2.05;
    scene.add(laptopGroup);

    const laptopBase = new THREE.Mesh(roundedBoxGeometry(1.95, 0.16, 1.25, 0.08), graphite);
    laptopBase.position.set(-1.95, -0.32, 0.12);
    laptopBase.rotation.x = -Math.PI / 2;
    laptopGroup.add(laptopBase);

    const laptopScreen = new THREE.Mesh(roundedBoxGeometry(1.85, 1.2, 0.12, 0.09), ink);
    laptopScreen.position.set(-1.95, 0.33, -0.48);
    laptopScreen.rotation.x = -0.25;
    laptopGroup.add(laptopScreen);

    const laptopPanel = new THREE.Mesh(roundedBoxGeometry(1.55, 0.84, 0.04, 0.05), screen);
    laptopPanel.position.set(-1.95, 0.37, -0.55);
    laptopPanel.rotation.x = -0.25;
    laptopGroup.add(laptopPanel);

    const laptopAppOptions = {
      width: 620,
      height: 300,
      size: 34,
      lineHeight: 48,
      weight: 800,
      scaleX: 1.02,
      scaleY: 0.48,
      color: "#232520",
      bg: "rgba(244,240,226,0.84)",
    };
    const laptopApp = makeTextSprite("Kindle Share\nClick Open app", laptopAppOptions);
    laptopApp.position.set(-1.95, 0.62, 0.28);
    laptopGroup.add(laptopApp);

    const folderLabel = makeTextSprite("~/Books", { size: 48, weight: 800, scaleX: 1.2, scaleY: 0.32, color: "#232520" });
    folderLabel.position.set(-1.95, 0.5, 0.38);
    folderLabel.visible = false;
    laptopGroup.add(folderLabel);

    const bookStack = new THREE.Group();
    bookStack.position.x = 2.05;
    scene.add(bookStack);
    for (let i = 0; i < 5; i += 1) {
      const book = new THREE.Mesh(roundedBoxGeometry(0.52, 0.12, 0.78, 0.03), bookMats[i % bookMats.length]);
      book.position.set(-2.55 + i * 0.16, -0.22 + i * 0.09, 1.15 - i * 0.02);
      book.rotation.set(-Math.PI / 2, 0.08, -0.12);
      bookStack.add(book);
    }

    const ebookCard = new THREE.Mesh(roundedBoxGeometry(0.64, 0.9, 0.035, 0.04), paper);
    ebookCard.position.set(-1.32, -0.22, 1.05);
    ebookCard.rotation.set(-Math.PI / 2, 0.1, 0.18);
    bookStack.add(ebookCard);
    const ebookLabel = makeTextSprite("EPUB -> MOBI\nAZW3\nPDF", {
      width: 360,
      height: 240,
      size: 36,
      lineHeight: 48,
      weight: 900,
      scaleX: 0.5,
      scaleY: 0.32,
      color: "#232520",
    });
    ebookLabel.position.set(-1.32, -0.08, 0.98);
    bookStack.add(ebookLabel);

    const kindleGroup = new THREE.Group();
    kindleGroup.position.x = 2.55;
    scene.add(kindleGroup);

    const kindleInk = ink.clone();
    const kindleGraphite = graphite.clone();
    const kindlePaper = paper.clone();

    const kindle = new THREE.Mesh(roundedBoxGeometry(1.34, 2.05, 0.18, 0.13), kindleInk);
    kindle.position.set(2.05, 0.25, 0.35);
    kindle.rotation.set(-0.12, -0.28, 0.03);
    kindleGroup.add(kindle);

    const kindleScreen = new THREE.Mesh(roundedBoxGeometry(1.02, 1.47, 0.04, 0.055), kindlePaper);
    kindleScreen.position.set(2.0, 0.34, 0.51);
    kindleScreen.rotation.set(-0.12, -0.28, 0.03);
    kindleGroup.add(kindleScreen);

    const kindleButton = new THREE.Mesh(new THREE.CylinderGeometry(0.105, 0.105, 0.025, 32), kindleGraphite);
    kindleButton.position.set(2.03, -0.66, 0.54);
    kindleButton.rotation.set(Math.PI / 2 - 0.12, 0, -0.28);
    kindleGroup.add(kindleButton);

    const leftPageButton = new THREE.Mesh(roundedBoxGeometry(0.035, 0.56, 0.035, 0.018), kindleGraphite.clone());
    leftPageButton.position.set(1.36, 0.22, 0.57);
    leftPageButton.rotation.set(-0.12, -0.28, 0.03);
    kindleGroup.add(leftPageButton);

    const rightPageButton = new THREE.Mesh(roundedBoxGeometry(0.035, 0.56, 0.035, 0.018), kindleGraphite.clone());
    rightPageButton.position.set(2.72, 0.22, 0.22);
    rightPageButton.rotation.set(-0.12, -0.28, 0.03);
    kindleGroup.add(rightPageButton);

    const kindleBrand = makeTextSprite("kindle", {
      width: 420,
      height: 90,
      size: 34,
      weight: 800,
      scaleX: 0.46,
      scaleY: 0.16,
      color: "#f4f0e2",
    });
    kindleBrand.position.set(2.04, -0.53, 0.56);
    kindleGroup.add(kindleBrand);

    const kindleListOptions = {
      width: 520,
      height: 300,
      size: 32,
      lineHeight: 52,
      weight: 800,
      scaleX: 0.92,
      scaleY: 0.54,
      color: "#232520",
      bg: "#f4f0e2",
    };
    const kindleList = makeTextSprite("Kindle\nBrowser closed", kindleListOptions);
    kindleList.position.set(2.0, 0.38, 0.57);
    kindleGroup.add(kindleList);

    const router = new THREE.Mesh(roundedBoxGeometry(0.74, 0.18, 0.55, 0.07), blue);
    router.position.set(2.05, -0.26, 1.04);
    router.rotation.x = -Math.PI / 2;
    scene.add(router);

    const urlLabelOptions = {
      width: 760,
      height: 110,
      size: 45,
      weight: 800,
      font: "monospace",
      scaleX: 1.8,
      scaleY: 0.32,
      color: "#1f211f",
    };
    const urlLabel = makeTextSprite("Laptop + ebooks", urlLabelOptions);
    urlLabel.position.set(2.05, 1.45, -0.1);
    scene.add(urlLabel);

    const arcs = [0.9, 1.25, 1.62].map((radius, index) => {
      const arc = createArc(radius, 0.15 + index * 0.1, index === 1 ? "#2b6f8f" : "#242521");
      arc.position.set(2.13, 0.3, 0.22);
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

    const laptopScreens = [
      "Kindle Share\nLaptop + ebooks\nReady",
      "Kindle Share\nOpen app\nLocal transfer",
      "Books folder\n~/Books selected\n18 books",
      "Sharing on\nhttp://192.168.1.7:8787\nCopy URL",
      "Copy this URL\n192.168.1.7:8787\nOpen on Kindle",
      "Server running\nKindle connected\nDownloading...",
      "Transfer done\nBo Gia.azw3\nReady",
    ];

    const stepScreens = [
      "kindle\nsleeping",
      "Browser\nclosed",
      "Waiting\nfor URL",
      "Waiting\nfor URL",
      "192.168.1.7\n8787\nOpen",
      "Bo Gia.azw3\nTap download",
      "READING\nBo Gia.azw3\nChapter 1",
    ];

    const stepUrls = [
      "Laptop + ebooks",
      "Open Kindle Share",
      "Choose ~/Books",
      "Start local server",
      "192.168.1.7:8787",
      "Downloading to Kindle",
      "Open book on Kindle",
    ];

    const cameraTargets = [
      { position: new THREE.Vector3(0.55, 3.35, 7.2), lookAt: new THREE.Vector3(0.62, 0.0, 0.3) },
      { position: new THREE.Vector3(0.0, 2.2, 4.6), lookAt: new THREE.Vector3(0.12, 0.34, -0.55) },
      { position: new THREE.Vector3(-0.02, 2.08, 4.25), lookAt: new THREE.Vector3(0.1, 0.38, -0.6) },
      { position: new THREE.Vector3(0.45, 2.28, 4.95), lookAt: new THREE.Vector3(0.48, 0.42, -0.35) },
      { position: new THREE.Vector3(1.8, 3.0, 6.7), lookAt: new THREE.Vector3(3.1, 0.34, 0.16) },
      { position: new THREE.Vector3(3.22, 2.55, 5.25), lookAt: new THREE.Vector3(4.55, 0.35, 0.46) },
      { position: new THREE.Vector3(3.55, 2.16, 4.35), lookAt: new THREE.Vector3(4.55, 0.34, 0.52) },
    ];

    const applyStep = (nextStep) => {
      state.activeStep = nextStep;
      updateTextSprite(laptopApp, laptopScreens[nextStep], laptopAppOptions);
      updateTextSprite(kindleList, stepScreens[nextStep], kindleListOptions);
      updateTextSprite(urlLabel, stepUrls[nextStep], urlLabelOptions);
      folderLabel.visible = nextStep >= 2;
      router.visible = nextStep >= 3;
      arcs.forEach((arc) => {
        arc.visible = nextStep >= 4;
      });
      particles.forEach((particle, index) => {
        particle.visible = nextStep >= 4 || (nextStep === 0 && index % 5 === 0);
      });
      setObjectOpacity(kindleGroup, nextStep >= 4 ? 1 : 0.18);
      setObjectOpacity(bookStack, nextStep <= 3 ? 1 : 0.38);
    };

    applyStep(state.activeStep);

    const handleStepChange = (event) => {
      applyStep(event.detail);
    };

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
      const target = cameraTargets[state.activeStep] || cameraTargets[0];
      camera.position.lerp(target.position, 0.035);
      const lookAt = target.lookAt.clone();
      lookAt.x += scroll * 0.08;
      lookAt.y -= scroll * 0.05;
      camera.lookAt(lookAt);

      laptopScreen.rotation.x = THREE.MathUtils.lerp(laptopScreen.rotation.x, state.activeStep === 0 ? -0.62 : -0.25, 0.045);
      laptopPanel.rotation.x = laptopScreen.rotation.x;
      laptopApp.position.y = THREE.MathUtils.lerp(laptopApp.position.y, state.activeStep === 0 ? 0.42 : 0.62, 0.06);

      arcs.forEach((arc, index) => {
        arc.material.opacity = 0.35 + Math.sin(elapsed * 2.4 + index) * 0.18 + 0.35;
      });

      particles.forEach((particle) => {
        const t = (elapsed * 0.18 + particle.userData.offset) % 1;
        const eased = 0.5 - Math.cos(t * Math.PI) / 2;
        const heightBoost = state.activeStep >= 5 ? 1.55 : 1.25;
        particle.position.set(
          THREE.MathUtils.lerp(0.5, 4.02, eased),
          0.02 + Math.sin(t * Math.PI) * heightBoost,
          0.45 + Math.sin(t * Math.PI * 2) * 0.18
        );
        particle.scale.setScalar(0.7 + Math.sin(t * Math.PI) * 0.8);
      });

      router.rotation.z = Math.sin(elapsed * 0.7) * 0.025;
      kindleGroup.position.y = Math.sin(elapsed * 0.8) * 0.015;
      frameId = requestAnimationFrame(animate);
      renderer.render(scene, camera);
    };

    window.addEventListener("resize", resize);
    mount.addEventListener("kindle-share-step", handleStepChange);
    resize();
    animate();

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener("resize", resize);
      mount.removeEventListener("kindle-share-step", handleStepChange);
      delete mount.__kindleShareState;
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

  useEffect(() => {
    if (mountRef.current?.__kindleShareState) {
      mountRef.current.__kindleShareState.activeStep = activeStep;
      mountRef.current.dispatchEvent(new CustomEvent("kindle-share-step", { detail: activeStep }));
    }
  }, [activeStep]);

  return <div className="diorama" ref={mountRef} aria-hidden="true" />;
}

function App() {
  const [step, setStep] = useState(0);
  const steps = [
    ["Laptop + ebooks", "Start with the computer and the book files already beside you."],
    ["Open app", "Kindle Share opens on the laptop and waits for a folder."],
    ["Choose folder", "Select the folder that contains PDF, MOBI, AZW, AZW3, or EPUB files."],
    ["Start server", "The app starts a small local server and shows a private Wi-Fi URL."],
    ["Open URL", "Type the local address into the Kindle browser."],
    ["Download book", "Tap a title and let Kindle pull the file directly."],
    ["Read on Kindle", "Open the downloaded book and keep reading."],
  ];

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
          <Diorama activeStep={step} />
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
          <div className="hero-demo" aria-label="Interactive transfer demo">
            {steps.map(([title], index) => (
              <button className={step === index ? "active" : ""} key={title} onClick={() => setStep(index)}>
                <span>0{index + 1}</span>
                {title}
              </button>
            ))}
          </div>
        </section>

        <section id="how" className="story">
          <div className="section-copy">
            <h2>Four small steps. One room.</h2>
            <p>Kindle Share feels like a quiet e-ink manual because the workflow is visible: laptop, app, folder, URL, Kindle browser, download, read.</p>
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
