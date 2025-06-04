//
//  Security.swift
//  StikJIT
//  from MeloNX
//  Created by s s on 2025/4/6.
//
import Security
import Foundation


typealias SecTaskRef = OpaquePointer
@_silgen_name("SecTaskCopyValueForEntitlement")
func SecTaskCopyValueForEntitlement(
    _ task: SecTaskRef,
    _ entitlement: NSString,
    _ error: NSErrorPointer
) -> CFTypeRef?

@_silgen_name("SecTaskCreateFromSelf")
func SecTaskCreateFromSelf(
    _ allocator: CFAllocator?
) -> SecTaskRef?

func checkAppEntitlement(_ ent: String) -> Bool {
    guard let task = SecTaskCreateFromSelf(nil) else {
        print("Failed to create SecTask")
        return false
    }
    
    guard let entitlements = SecTaskCopyValueForEntitlement(task, ent as NSString, nil) else {
        print("Failed to get entitlements")
        return false
    }

    // CFTypeRef can be either a CFBoolean or CFNumber representing a boolean
    let typeID = CFGetTypeID(entitlements)
    if typeID == CFBooleanGetTypeID() {
        let value = unsafeBitCast(entitlements, to: CFBoolean.self)
        return CFBooleanGetValue(value)
    } else if typeID == CFNumberGetTypeID() {
        // Bridge to NSNumber for convenience
        let number = unsafeBitCast(entitlements, to: CFNumber.self) as NSNumber
        return number.boolValue
    } else {
        return false
    }
}
