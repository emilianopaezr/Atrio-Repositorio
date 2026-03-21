const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const logoPath = path.join(projectRoot, 'assets', 'images', 'logo_blanco.png');
const outputPath = path.join(projectRoot, 'assets', 'images', 'app_icon.png');
const outputFgPath = path.join(projectRoot, 'assets', 'images', 'app_icon_foreground.png');

// Simple PNG decoder
function decodePNG(buffer) {
  // Verify PNG signature
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buffer.compare(sig, 0, 8, 0, 8) !== 0) throw new Error('Not a PNG');

  let offset = 8;
  let width, height, bitDepth, colorType;
  let idatBuffers = [];

  while (offset < buffer.length) {
    const length = buffer.readUInt32BE(offset);
    const type = buffer.toString('ascii', offset + 4, offset + 8);
    const data = buffer.subarray(offset + 8, offset + 8 + length);

    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
    } else if (type === 'IDAT') {
      idatBuffers.push(data);
    } else if (type === 'IEND') {
      break;
    }

    offset += 12 + length;
  }

  const compressed = Buffer.concat(idatBuffers);
  const decompressed = zlib.inflateSync(compressed);

  // Parse scanlines (assuming RGBA or RGB)
  const channels = colorType === 6 ? 4 : colorType === 2 ? 3 : colorType === 4 ? 2 : 1;
  const hasAlpha = colorType === 6 || colorType === 4;
  const bpp = channels; // bytes per pixel (assuming 8-bit depth)
  const rowBytes = width * bpp;

  const pixels = Buffer.alloc(width * height * 4); // Always output RGBA

  let srcOffset = 0;
  for (let y = 0; y < height; y++) {
    const filterType = decompressed[srcOffset++];
    const row = Buffer.alloc(rowBytes);
    const prevRow = y > 0 ? Buffer.alloc(rowBytes) : Buffer.alloc(rowBytes);

    // Get previous row
    if (y > 0) {
      // Reconstruct from already-decoded pixels
    }

    // Unfilter
    for (let x = 0; x < rowBytes; x++) {
      const raw = decompressed[srcOffset + x];
      const a = x >= bpp ? row[x - bpp] : 0; // left
      let b = 0, c = 0;

      // Get values from previous scanline
      if (y > 0) {
        const prevSrcStart = 1 + (y - 1) * (rowBytes + 1);
        // We need to store decoded rows... let me simplify
      }

      switch (filterType) {
        case 0: row[x] = raw; break; // None
        case 1: row[x] = (raw + a) & 0xFF; break; // Sub
        case 2: row[x] = raw; break; // Up (simplified - need prev row)
        case 3: row[x] = (raw + Math.floor(a / 2)) & 0xFF; break; // Average
        case 4: row[x] = (raw + a) & 0xFF; break; // Paeth (simplified)
        default: row[x] = raw;
      }
    }

    srcOffset += rowBytes;

    // Copy to RGBA output
    for (let x = 0; x < width; x++) {
      const dstIdx = (y * width + x) * 4;
      if (channels === 4) {
        pixels[dstIdx] = row[x * 4];
        pixels[dstIdx + 1] = row[x * 4 + 1];
        pixels[dstIdx + 2] = row[x * 4 + 2];
        pixels[dstIdx + 3] = row[x * 4 + 3];
      } else if (channels === 3) {
        pixels[dstIdx] = row[x * 3];
        pixels[dstIdx + 1] = row[x * 3 + 1];
        pixels[dstIdx + 2] = row[x * 3 + 2];
        pixels[dstIdx + 3] = 255;
      }
    }
  }

  return { width, height, pixels, channels, colorType };
}

// Better approach: use a proper scanline-by-scanline PNG decoder
function decodePNGProper(buffer) {
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buffer.compare(sig, 0, 8, 0, 8) !== 0) throw new Error('Not a PNG');

  let offset = 8;
  let width, height, bitDepth, colorType;
  let idatBuffers = [];

  while (offset < buffer.length) {
    const length = buffer.readUInt32BE(offset);
    const type = buffer.toString('ascii', offset + 4, offset + 8);
    const data = buffer.subarray(offset + 8, offset + 8 + length);

    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
      console.log(`PNG: ${width}x${height}, bit depth: ${bitDepth}, color type: ${colorType}`);
    } else if (type === 'IDAT') {
      idatBuffers.push(data);
    } else if (type === 'IEND') {
      break;
    }

    offset += 12 + length;
  }

  const compressed = Buffer.concat(idatBuffers);
  const raw = zlib.inflateSync(compressed);

  const channels = colorType === 6 ? 4 : colorType === 2 ? 3 : colorType === 4 ? 2 : 1;
  const bpp = channels * (bitDepth / 8);
  const rowBytes = width * bpp;

  const pixels = Buffer.alloc(width * height * 4);
  const rows = [];

  let pos = 0;
  for (let y = 0; y < height; y++) {
    const filterType = raw[pos++];
    const currentRow = Buffer.alloc(rowBytes);
    const prevRow = y > 0 ? rows[y - 1] : Buffer.alloc(rowBytes);

    for (let x = 0; x < rowBytes; x++) {
      const rawByte = raw[pos + x];
      const a = x >= bpp ? currentRow[x - Math.floor(bpp)] : 0;
      const b = prevRow[x];
      const c = (x >= bpp && y > 0) ? prevRow[x - Math.floor(bpp)] : 0;

      switch (filterType) {
        case 0: currentRow[x] = rawByte; break;
        case 1: currentRow[x] = (rawByte + a) & 0xFF; break;
        case 2: currentRow[x] = (rawByte + b) & 0xFF; break;
        case 3: currentRow[x] = (rawByte + Math.floor((a + b) / 2)) & 0xFF; break;
        case 4: {
          const p = a + b - c;
          const pa = Math.abs(p - a);
          const pb = Math.abs(p - b);
          const pc = Math.abs(p - c);
          const pr = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
          currentRow[x] = (rawByte + pr) & 0xFF;
          break;
        }
        default: currentRow[x] = rawByte;
      }
    }

    pos += rowBytes;
    rows.push(Buffer.from(currentRow));

    for (let x = 0; x < width; x++) {
      const dstIdx = (y * width + x) * 4;
      if (channels === 4) {
        pixels[dstIdx] = currentRow[x * 4];
        pixels[dstIdx + 1] = currentRow[x * 4 + 1];
        pixels[dstIdx + 2] = currentRow[x * 4 + 2];
        pixels[dstIdx + 3] = currentRow[x * 4 + 3];
      } else if (channels === 3) {
        pixels[dstIdx] = currentRow[x * 3];
        pixels[dstIdx + 1] = currentRow[x * 3 + 1];
        pixels[dstIdx + 2] = currentRow[x * 3 + 2];
        pixels[dstIdx + 3] = 255;
      } else if (channels === 2) {
        pixels[dstIdx] = currentRow[x * 2];
        pixels[dstIdx + 1] = currentRow[x * 2];
        pixels[dstIdx + 2] = currentRow[x * 2];
        pixels[dstIdx + 3] = currentRow[x * 2 + 1];
      } else {
        pixels[dstIdx] = currentRow[x];
        pixels[dstIdx + 1] = currentRow[x];
        pixels[dstIdx + 2] = currentRow[x];
        pixels[dstIdx + 3] = 255;
      }
    }
  }

  return { width, height, pixels };
}

// PNG encoder
function encodePNG(width, height, pixels) {
  const chunks = [];

  // Signature
  chunks.push(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));

  function makeChunk(type, data) {
    const typeBuffer = Buffer.from(type, 'ascii');
    const lengthBuffer = Buffer.alloc(4);
    lengthBuffer.writeUInt32BE(data.length, 0);

    const crcData = Buffer.concat([typeBuffer, data]);
    const crc = crc32(crcData);
    const crcBuffer = Buffer.alloc(4);
    crcBuffer.writeUInt32BE(crc, 0);

    return Buffer.concat([lengthBuffer, typeBuffer, data, crcBuffer]);
  }

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace
  chunks.push(makeChunk('IHDR', ihdr));

  // IDAT - create raw image data with filter bytes
  const rawData = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    rawData[y * (1 + width * 4)] = 0; // filter: None
    for (let x = 0; x < width; x++) {
      const srcIdx = (y * width + x) * 4;
      const dstIdx = y * (1 + width * 4) + 1 + x * 4;
      rawData[dstIdx] = pixels[srcIdx];
      rawData[dstIdx + 1] = pixels[srcIdx + 1];
      rawData[dstIdx + 2] = pixels[srcIdx + 2];
      rawData[dstIdx + 3] = pixels[srcIdx + 3];
    }
  }

  const compressed = zlib.deflateSync(rawData, { level: 9 });
  chunks.push(makeChunk('IDAT', compressed));

  // IEND
  chunks.push(makeChunk('IEND', Buffer.alloc(0)));

  return Buffer.concat(chunks);
}

// CRC32
function crc32(data) {
  let crc = 0xFFFFFFFF;
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) {
      if (c & 1) c = 0xEDB88320 ^ (c >>> 1);
      else c = c >>> 1;
    }
    table[i] = c;
  }
  for (let i = 0; i < data.length; i++) {
    crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >>> 8);
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

// Bilinear resize
function resize(src, srcW, srcH, dstW, dstH) {
  const dst = Buffer.alloc(dstW * dstH * 4);
  const xRatio = srcW / dstW;
  const yRatio = srcH / dstH;

  for (let y = 0; y < dstH; y++) {
    for (let x = 0; x < dstW; x++) {
      const srcX = x * xRatio;
      const srcY = y * yRatio;
      const x0 = Math.floor(srcX);
      const y0 = Math.floor(srcY);
      const x1 = Math.min(x0 + 1, srcW - 1);
      const y1 = Math.min(y0 + 1, srcH - 1);
      const xFrac = srcX - x0;
      const yFrac = srcY - y0;

      const dstIdx = (y * dstW + x) * 4;
      for (let c = 0; c < 4; c++) {
        const tl = src[(y0 * srcW + x0) * 4 + c];
        const tr = src[(y0 * srcW + x1) * 4 + c];
        const bl = src[(y1 * srcW + x0) * 4 + c];
        const br = src[(y1 * srcW + x1) * 4 + c];
        const top = tl + (tr - tl) * xFrac;
        const bottom = bl + (br - bl) * xFrac;
        dst[dstIdx + c] = Math.round(top + (bottom - top) * yFrac);
      }
    }
  }
  return dst;
}

// Main
try {
  console.log('Reading logo...');
  const logoBuffer = fs.readFileSync(logoPath);
  const logo = decodePNGProper(logoBuffer);
  console.log(`Logo decoded: ${logo.width}x${logo.height}`);

  // Find bounding box of non-transparent pixels
  let minX = logo.width, minY = logo.height, maxX = 0, maxY = 0;
  for (let y = 0; y < logo.height; y++) {
    for (let x = 0; x < logo.width; x++) {
      const idx = (y * logo.width + x) * 4;
      const a = logo.pixels[idx + 3];
      if (a > 10) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  console.log(`Bounding box: (${minX}, ${minY}) -> (${maxX}, ${maxY})`);
  const cropW = maxX - minX + 1;
  const cropH = maxY - minY + 1;
  console.log(`Crop size: ${cropW}x${cropH}`);

  // Crop
  const cropped = Buffer.alloc(cropW * cropH * 4);
  for (let y = 0; y < cropH; y++) {
    for (let x = 0; x < cropW; x++) {
      const srcIdx = ((y + minY) * logo.width + (x + minX)) * 4;
      const dstIdx = (y * cropW + x) * 4;
      cropped[dstIdx] = logo.pixels[srcIdx];
      cropped[dstIdx + 1] = logo.pixels[srcIdx + 1];
      cropped[dstIdx + 2] = logo.pixels[srcIdx + 2];
      cropped[dstIdx + 3] = logo.pixels[srcIdx + 3];
    }
  }

  const iconSize = 1024;

  // --- Generate combined app_icon.png ---
  const icon = Buffer.alloc(iconSize * iconSize * 4);
  // Fill lime green (#D4FF00)
  for (let i = 0; i < iconSize * iconSize; i++) {
    icon[i * 4] = 0xD4;
    icon[i * 4 + 1] = 0xFF;
    icon[i * 4 + 2] = 0x00;
    icon[i * 4 + 3] = 0xFF;
  }

  // Scale logo to ~55% of icon size
  const targetSize = Math.round(iconSize * 0.55);
  const scale = targetSize / Math.max(cropW, cropH);
  const scaledW = Math.round(cropW * scale);
  const scaledH = Math.round(cropH * scale);
  const scaledLogo = resize(cropped, cropW, cropH, scaledW, scaledH);

  // Center on icon
  const offX = Math.floor((iconSize - scaledW) / 2);
  const offY = Math.floor((iconSize - scaledH) / 2);

  // Alpha composite
  for (let y = 0; y < scaledH; y++) {
    for (let x = 0; x < scaledW; x++) {
      const srcIdx = (y * scaledW + x) * 4;
      const dstIdx = ((y + offY) * iconSize + (x + offX)) * 4;
      const sa = scaledLogo[srcIdx + 3] / 255;
      const da = 1 - sa;

      icon[dstIdx] = Math.round(scaledLogo[srcIdx] * sa + icon[dstIdx] * da);
      icon[dstIdx + 1] = Math.round(scaledLogo[srcIdx + 1] * sa + icon[dstIdx + 1] * da);
      icon[dstIdx + 2] = Math.round(scaledLogo[srcIdx + 2] * sa + icon[dstIdx + 2] * da);
      icon[dstIdx + 3] = 255;
    }
  }

  const iconPng = encodePNG(iconSize, iconSize, icon);
  fs.writeFileSync(outputPath, iconPng);
  console.log(`Generated: ${outputPath} (${iconPng.length} bytes)`);

  // --- Generate adaptive foreground (transparent bg + logo at ~45% size) ---
  const fg = Buffer.alloc(iconSize * iconSize * 4); // all zeros = transparent

  const fgTargetSize = Math.round(iconSize * 0.45);
  const fgScale = fgTargetSize / Math.max(cropW, cropH);
  const fgScaledW = Math.round(cropW * fgScale);
  const fgScaledH = Math.round(cropH * fgScale);
  const fgScaledLogo = resize(cropped, cropW, cropH, fgScaledW, fgScaledH);

  const fgOffX = Math.floor((iconSize - fgScaledW) / 2);
  const fgOffY = Math.floor((iconSize - fgScaledH) / 2);

  for (let y = 0; y < fgScaledH; y++) {
    for (let x = 0; x < fgScaledW; x++) {
      const srcIdx = (y * fgScaledW + x) * 4;
      const dstIdx = ((y + fgOffY) * iconSize + (x + fgOffX)) * 4;
      fg[dstIdx] = fgScaledLogo[srcIdx];
      fg[dstIdx + 1] = fgScaledLogo[srcIdx + 1];
      fg[dstIdx + 2] = fgScaledLogo[srcIdx + 2];
      fg[dstIdx + 3] = fgScaledLogo[srcIdx + 3];
    }
  }

  const fgPng = encodePNG(iconSize, iconSize, fg);
  fs.writeFileSync(outputFgPath, fgPng);
  console.log(`Generated: ${outputFgPath} (${fgPng.length} bytes)`);

  console.log('Done!');
} catch (err) {
  console.error('Error:', err.message);
  console.error(err.stack);
  process.exit(1);
}
