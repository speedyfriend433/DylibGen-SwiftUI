//
//  DylibGenerator.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import Foundation
import Darwin

class DylibGenerator {
    enum MakeError: Int, Error {
        case commandNotFound = 0
        case compilationFailed = 1
        case executionFailed = 2
        case notJailbroken = 3
        case permissionDenied = 4
        case theosNotFound = 5
    }
    
    private let fileManager = FileManager.default
    
    // Add the shell command functions
    @discardableResult
    private func shell(_ command: String, asRoot: Bool = false) -> Int {
        if asRoot {
            guard let rootPath = findJBRoot() else {
                print("Jailbreak root not found")
                return -1
            }
            return runCommand("/usr/bin/bash", ["-c", command], 0, rootPath)
        } else {
            return runCommand("/usr/bin/bash", ["-c", command], 501)
        }
    }
    
    // C function declarations
    @_silgen_name("posix_spawnattr_set_persona_np")
    private func posix_spawnattr_set_persona_np(_ attr: UnsafeMutablePointer<posix_spawnattr_t?>, _ persona_id: uid_t, _ flags: UInt32) -> Int32
    
    @_silgen_name("posix_spawnattr_set_persona_uid_np")
    private func posix_spawnattr_set_persona_uid_np(_ attr: UnsafeMutablePointer<posix_spawnattr_t?>, _ persona_id: uid_t) -> Int32
    
    @_silgen_name("posix_spawnattr_set_persona_gid_np")
    private func posix_spawnattr_set_persona_gid_np(_ attr: UnsafeMutablePointer<posix_spawnattr_t?>, _ persona_id: uid_t) -> Int32
    
    private func runCommand(_ command: String, _ args: [String], _ uid: uid_t, _ rootPath: String = "") -> Int {
        var pid: pid_t = 0
        let args: [String] = [String(command.split(separator: "/").last!)] + args
        let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
        let env = ["PATH=/usr/local/sbin:\(rootPath)/usr/local/sbin:/usr/local/bin:\(rootPath)/usr/local/bin:/usr/sbin:\(rootPath)/usr/sbin:/usr/bin:\(rootPath)/usr/bin:/sbin:\(rootPath)/sbin:/bin:\(rootPath)/bin:/usr/bin/X11:\(rootPath)/usr/bin/X11:/usr/games:\(rootPath)/usr/games"]
        let proenv: [UnsafeMutablePointer<CChar>?] = env.map { $0.withCString(strdup) }
        defer { for case let pro? in proenv { free(pro) } }
        
        var attr: posix_spawnattr_t?
        posix_spawnattr_init(&attr)
        _ = posix_spawnattr_set_persona_np(&attr, 99, 1)
        _ = posix_spawnattr_set_persona_uid_np(&attr, uid)
        _ = posix_spawnattr_set_persona_gid_np(&attr, uid)
        
        guard posix_spawn(&pid, rootPath + command, nil, &attr, argv + [nil], proenv + [nil]) == 0 else {
            print("Failed to spawn process")
            return -1
        }
        
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        return Int(status)
    }
    
    private func findJBRoot() -> String? {
        if FileManager.default.fileExists(atPath: "/usr/bin/bash") {
            return ""
        } else if FileManager.default.fileExists(atPath: "/var/jb/usr/bin/bash") {
            return "/var/jb"
        } else {
            do {
                let applicationsPath = "/var/containers/Bundle/Application"
                if let jbRoot = try FileManager.default.contentsOfDirectory(atPath: applicationsPath).first(where: { $0.hasPrefix(".jbroot") }) {
                    return "\(applicationsPath)/\(jbRoot)"
                } else {
                    return nil
                }
            } catch {
                print(error)
                return nil
            }
        }
    }
    
    func generateDylib(fromSource source: String, name: String) async throws -> URL {
        print("Checking jailbreak status...")
        guard findJBRoot() != nil else {
            throw MakeError.notJailbroken
        }
        
        print("Setting up working directory...")
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let workDir = documentsURL.appendingPathComponent("DylibBuild_\(UUID().uuidString)")
        
        try fileManager.createDirectory(at: workDir, withIntermediateDirectories: true, attributes: nil)
        
        print("Writing source file...")
        let sourceURL = workDir.appendingPathComponent("\(name).m")
        try source.write(to: sourceURL, atomically: true, encoding: .utf8)
        
        print("Creating Makefile...")
        try createMakefile(at: workDir, name: name)
        
        print("Running compilation commands...")
        // Execute make commands with root privileges
        let result = shell("cd \(workDir.path) && make clean && make", asRoot: true)
        
        if result != 0 {
            throw MakeError.compilationFailed
        }
        
        // Set permissions for the generated dylib
        _ = shell("chmod 755 \(workDir.path)/\(name).dylib", asRoot: true)
        
        let dylibURL = workDir.appendingPathComponent("\(name).dylib")
        guard fileManager.fileExists(atPath: dylibURL.path) else {
            throw MakeError.compilationFailed
        }
        
        return dylibURL
    }
    
    private func createMakefile(at directory: URL, name: String) throws {
        let makefileContent = """
        THEOS=/var/theos
        TARGET := iphone:clang:latest:7.0
        ARCHS = arm64 arm64e

        include $(THEOS)/makefiles/common.mk

        TWEAK_NAME = \(name)
        \(name)_FILES = \(name).m
        \(name)_CFLAGS = -fobjc-arc
        \(name)_LIBRARIES = substrate

        include $(THEOS)/makefiles/tweak.mk
        """
        
        try makefileContent.write(
            to: directory.appendingPathComponent("Makefile"),
            atomically: true,
            encoding: .utf8
        )
        
        // Set Makefile permissions
        _ = shell("chmod 644 \(directory.path)/Makefile", asRoot: true)
    }
}

// Add this extension to handle checking device status
extension DylibGenerator {
    func checkDeviceStatus() -> (isJailbroken: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check for jailbreak
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/var/theos"
        ]
        
        let foundJailbreakPaths = jailbreakPaths.filter { fileManager.fileExists(atPath: $0) }
        if foundJailbreakPaths.isEmpty {
            issues.append("No jailbreak indicators found")
        }
        
        // Check Theos
        if !fileManager.fileExists(atPath: "/var/theos") {
            issues.append("Theos not found at /var/theos")
        }
        
        // Check required tools
        let requiredTools = ["/usr/bin/make", "/usr/bin/clang", "/bin/sh"]
        for tool in requiredTools {
            if !fileManager.fileExists(atPath: tool) {
                issues.append("Required tool not found: \(tool)")
            }
        }
        
        // Check write permissions
        let testPath = "/var/mobile/test_write_permission"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try fileManager.removeItem(atPath: testPath)
        } catch {
            issues.append("Write permission test failed: \(error.localizedDescription)")
        }
        
        return (isJailbroken: !foundJailbreakPaths.isEmpty, issues: issues)
    }
}
